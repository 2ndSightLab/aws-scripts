#!/bin/bash

# assume-role.sh — Create AWS CLI source profile and role profile
# Variables may be pre-set by the calling project (requirement 2.0)
# Any unset required values will be prompted for interactively
# Set RESET_CREDENTIALS=1 to force credential re-entry when source profile already exists

# --- Select existing profile or create new one ---
# select_profile: Display profiles, filter by letter input, select by number input
# Args: ARRAY_NAME_VAR (nameref), PROMPT_TEXT, ALLOW_CREATE (y/n)
# Sets: _SELECTED_PROFILE
select_profile() {
  local -n _profiles_ref=$1
  local _prompt="$2"
  local _allow_create="$3"
  local _filtered=()
  local _display=("${_profiles_ref[@]}")

  while true; do
    echo ""
    for i in "${!_display[@]}"; do
      echo "  $((i+1))) ${_display[$i]}"
    done
    if [ "${_allow_create}" = "y" ]; then
      echo "  $((${#_display[@]}+1))) Create new profile"
    fi
    read -r -p "${_prompt}: " _input
    if [[ "${_input}" =~ ^[0-9]+$ ]]; then
      if [ "${_allow_create}" = "y" ] && [ "${_input}" -eq $((${#_display[@]}+1)) ]; then
        _SELECTED_PROFILE=""
        return 1
      elif [ "${_input}" -ge 1 ] && [ "${_input}" -le ${#_display[@]} ]; then
        _SELECTED_PROFILE="${_display[$((_input-1))]}"
        return 0
      fi
      echo "Invalid selection."
    elif [[ "${_input}" =~ ^[a-zA-Z] ]]; then
      _filtered=()
      for p in "${_profiles_ref[@]}"; do
        if [[ "${p,,}" == *"${_input,,}"* ]]; then
          _filtered+=("$p")
        fi
      done
      if [ ${#_filtered[@]} -eq 0 ]; then
        echo "No profiles match '${_input}'. Showing all."
        _display=("${_profiles_ref[@]}")
      else
        _display=("${_filtered[@]}")
      fi
    else
      echo "Invalid input."
    fi
  done
}

echo "Available AWS CLI profiles:"
mapfile -t _EXISTING_PROFILES < <(aws configure list-profiles 2>/dev/null)
select_profile _EXISTING_PROFILES "Select profile [number] or type to filter" "y"
if [ $? -eq 0 ]; then
  PROFILE="${_SELECTED_PROFILE}"
  echo "Using profile: ${PROFILE}"
  return 0
fi

# validate_input: Validates a variable value against pattern, max length, and injection characters
# Args: VAR_NAME, VAR_VALUE, PATTERN, MAX_LENGTH, EXPECTED_FORMAT
validate_input() {
  local VAR_NAME="$1"
  local VAR_VALUE="$2"
  local PATTERN="$3"
  local MAX_LENGTH="$4"
  local EXPECTED_FORMAT="$5"

  if [ -z "$VAR_VALUE" ]; then
    return 0
  fi

  if [ ${#VAR_VALUE} -gt "$MAX_LENGTH" ]; then
    echo "Error: $VAR_NAME exceeds maximum length of $MAX_LENGTH characters" >&2
    exit 1
  fi

  if echo "$VAR_VALUE" | grep -qE '[;&|`$(){}!<>\\]'; then
    echo "Error: $VAR_NAME contains invalid special characters" >&2
    exit 1
  fi

  if [ -n "$PATTERN" ]; then
    if ! echo "$VAR_VALUE" | grep -qE "$PATTERN"; then
      echo "Error: $VAR_NAME has invalid format. Expected: $EXPECTED_FORMAT" >&2
      exit 1
    fi
  fi

  return 0
}

# Default SECRETS_MANAGER_USED and EXTERNAL_ID_USED to N if not set
SECRETS_MANAGER_USED="${SECRETS_MANAGER_USED:-N}"
EXTERNAL_ID_USED="${EXTERNAL_ID_USED:-N}"
validate_input "SECRETS_MANAGER_USED" "$SECRETS_MANAGER_USED" "^[YN]$" 1 "Y or N"
validate_input "EXTERNAL_ID_USED" "$EXTERNAL_ID_USED" "^[YN]$" 1 "Y or N"

# 2.3.1 Source profile name (needed early for credential check)
if [ -z "${SOURCE_PROFILE:-}" ]; then
  echo "Available AWS CLI profiles:"
  mapfile -t PROFILES < <(aws configure list-profiles 2>/dev/null)
  if [ ${#PROFILES[@]} -eq 0 ]; then
    echo "Error: No AWS CLI profiles found" >&2
    exit 1
  fi
  select_profile PROFILES "Select source profile [number] or type to filter" "n"
  if [ $? -eq 0 ]; then
    SOURCE_PROFILE="${_SELECTED_PROFILE}"
  else
    echo "Error: No profile selected" >&2
    exit 1
  fi
fi
validate_input "SOURCE_PROFILE" "$SOURCE_PROFILE" "^[a-zA-Z0-9_-]+$" 128 "alphanumeric, hyphens, underscores only"

# --- Check if source profile credentials can be reused ---
SKIP_CREDENTIALS=0
if [ "${RESET_CREDENTIALS:-0}" != "1" ]; then
  EXISTING_KEY=$(aws configure get aws_access_key_id --profile "$SOURCE_PROFILE" 2>&1)
  EXISTING_KEY_RC=$?
  if [ $EXISTING_KEY_RC -eq 0 ] && [ -n "$EXISTING_KEY" ]; then
    echo "Source profile '$SOURCE_PROFILE' already has credentials configured."
    SKIP_CREDENTIALS=1
  fi
  EXISTING_KEY=""
  unset EXISTING_KEY
  unset EXISTING_KEY_RC
fi

if [ $SKIP_CREDENTIALS -eq 0 ]; then

  # --- Secrets Manager mode (requirement 2.1, 2.2) ---
  AWS_ACCESS_KEY_ID="${AWS_ACCESS_KEY_ID:-}"
  AWS_SECRET_ACCESS_KEY="${AWS_SECRET_ACCESS_KEY:-}"

  # 2.1 Ask if creds are in a SECRETS_ARN if not populated
  # Skip Secrets Manager prompt entirely if SECRETS_MANAGER_USED is set to N
  if [ "${SECRETS_MANAGER_USED:-}" != "N" ]; then
    if [ -z "${SECRETS_ARN:-}" ] && [ -z "$AWS_ACCESS_KEY_ID" ]; then
      echo "Enter Secrets Manager ARN (or press Enter to input credentials manually):"
      read -r SECRETS_ARN
      if [ -n "$SECRETS_ARN" ]; then
        validate_input "SECRETS_ARN" "$SECRETS_ARN" "^arn:aws:secretsmanager:[a-z0-9-]+:[0-9]{12}:secret:.+$" 2048 "arn:aws:secretsmanager:<region>:<account-id>:secret:<name>"
      fi
    fi
  fi

  # 2.2 If SECRETS_ARN is provided, retrieve and parse the secret
  if [ -n "${SECRETS_ARN:-}" ] && [ -z "$AWS_ACCESS_KEY_ID" ]; then
    echo "Retrieving credentials from Secrets Manager..."
    SECRET_VALUE=$(aws secretsmanager get-secret-value --secret-id "$SECRETS_ARN" --query 'SecretString' --output text)
    if [ $? -ne 0 ]; then
      echo "Error: Failed to retrieve secret from Secrets Manager" >&2
      exit 1
    fi
    if [ -z "$SECRET_VALUE" ]; then
      echo "Error: Secret returned an empty value" >&2
      exit 1
    fi

    # 2.2.1 Parse secret JSON
    AWS_ACCESS_KEY_ID=$(echo "$SECRET_VALUE" | grep -o '"AWS_ACCESS_KEY_ID"[[:space:]]*:[[:space:]]*"[^"]*"' | sed 's/.*:.*"\([^"]*\)"/\1/')
    AWS_SECRET_ACCESS_KEY=$(echo "$SECRET_VALUE" | grep -o '"AWS_SECRET_ACCESS_KEY"[[:space:]]*:[[:space:]]*"[^"]*"' | sed 's/.*:.*"\([^"]*\)"/\1/')

    # 2.2.2 Wipe secret value immediately
    SECRET_VALUE=""
    unset SECRET_VALUE

    if [ -z "$AWS_ACCESS_KEY_ID" ]; then
      echo "Error: AWS_ACCESS_KEY_ID not found in secret JSON" >&2
      exit 1
    fi
    if [ -z "$AWS_SECRET_ACCESS_KEY" ]; then
      echo "Error: AWS_SECRET_ACCESS_KEY not found in secret JSON" >&2
      exit 1
    fi
  fi

  # 2.3.2 AWS access key ID
  if [ -z "${AWS_ACCESS_KEY_ID:-}" ]; then
    echo "Enter AWS access key ID:"
    read -r AWS_ACCESS_KEY_ID
    if [ -z "$AWS_ACCESS_KEY_ID" ]; then
      echo "Error: AWS_ACCESS_KEY_ID is required" >&2
      exit 1
    fi
  fi
  validate_input "AWS_ACCESS_KEY_ID" "$AWS_ACCESS_KEY_ID" "^[A-Z0-9]{20}$" 20 "exactly 20 uppercase alphanumeric characters"

  # 2.3.3 AWS secret access key (read -s per requirement 7.2)
  if [ -z "${AWS_SECRET_ACCESS_KEY:-}" ]; then
    echo "Enter AWS secret access key:"
    read -rs AWS_SECRET_ACCESS_KEY
    echo ""
    if [ -z "$AWS_SECRET_ACCESS_KEY" ]; then
      echo "Error: AWS_SECRET_ACCESS_KEY is required" >&2
      exit 1
    fi
  fi
  if [ ${#AWS_SECRET_ACCESS_KEY} -ne 40 ]; then
    echo "Error: AWS_SECRET_ACCESS_KEY must be exactly 40 characters" >&2
    exit 1
  fi

  # 2.3.4 Region
  if [ -z "${REGION:-}" ]; then
    echo "Enter region:"
    read -r REGION
    if [ -z "$REGION" ]; then
      echo "Error: REGION is required" >&2
      exit 1
    fi
  fi
  validate_input "REGION" "$REGION" "^[a-z]{2}(-[a-z]+)+-[0-9]+$" 32 "AWS region like us-east-1"

  # --- 4.1 Configure source profile ---
  aws configure set aws_access_key_id "$AWS_ACCESS_KEY_ID" --profile "$SOURCE_PROFILE"
  if [ $? -ne 0 ]; then
    echo "Error: Failed to set aws_access_key_id on source profile '$SOURCE_PROFILE'" >&2
    exit 1
  fi

  aws configure set aws_secret_access_key "$AWS_SECRET_ACCESS_KEY" --profile "$SOURCE_PROFILE"
  if [ $? -ne 0 ]; then
    echo "Error: Failed to set aws_secret_access_key on source profile '$SOURCE_PROFILE'" >&2
    exit 1
  fi

  # 7.3 Wipe credential variables
  AWS_ACCESS_KEY_ID=""
  unset AWS_ACCESS_KEY_ID
  AWS_SECRET_ACCESS_KEY=""
  unset AWS_SECRET_ACCESS_KEY

  aws configure set region "$REGION" --profile "$SOURCE_PROFILE"
  if [ $? -ne 0 ]; then
    echo "Error: Failed to set region on source profile '$SOURCE_PROFILE'" >&2
    exit 1
  fi

  # 2.3.9 Output format
  if [ -z "${OUTPUT:-}" ]; then
    echo "Enter output format (json or text):"
    read -r OUTPUT
    if [ -z "$OUTPUT" ]; then
      echo "Error: OUTPUT is required" >&2
      exit 1
    fi
  fi
  validate_input "OUTPUT" "$OUTPUT" "^(json|text)$" 16 "json or text"

  aws configure set output "$OUTPUT" --profile "$SOURCE_PROFILE"
  if [ $? -ne 0 ]; then
    echo "Error: Failed to set output on source profile '$SOURCE_PROFILE'" >&2
    exit 1
  fi

fi

# --- Prompt for remaining values needed for role profile ---

# 2.3.4 Region (if credentials were skipped, still need it for role profile)
if [ -z "${REGION:-}" ]; then
  echo "Enter region:"
  read -r REGION
  if [ -z "$REGION" ]; then
    echo "Error: REGION is required" >&2
    exit 1
  fi
fi
validate_input "REGION" "$REGION" "^[a-z]{2}(-[a-z]+)+-[0-9]+$" 32 "AWS region like us-east-1"

# 2.3.9 Output format (if credentials were skipped, still need it for role profile)
if [ -z "${OUTPUT:-}" ]; then
  echo "Enter output format (json or text):"
  read -r OUTPUT
  if [ -z "$OUTPUT" ]; then
    echo "Error: OUTPUT is required" >&2
    exit 1
  fi
fi
validate_input "OUTPUT" "$OUTPUT" "^(json|text)$" 16 "json or text"

# 2.3.5 Role profile name
if [ -z "${PROFILE:-}" ]; then
  echo "Enter role profile name:"
  read -r PROFILE
  if [ -z "$PROFILE" ]; then
    echo "Error: PROFILE is required" >&2
    exit 1
  fi
fi
validate_input "PROFILE" "$PROFILE" "^[a-zA-Z0-9_-]+$" 128 "alphanumeric, hyphens, underscores only"

# 2.3.6 Role ARN
if [ -z "${ROLE_ARN:-}" ]; then
  echo "Enter role ARN:"
  read -r ROLE_ARN
  if [ -z "$ROLE_ARN" ]; then
    echo "Error: ROLE_ARN is required" >&2
    exit 1
  fi
fi
validate_input "ROLE_ARN" "$ROLE_ARN" "^arn:aws:iam::[0-9]{12}:role/.+$" 2048 "arn:aws:iam::<account-id>:role/<role-name>"

# 2.3.7 MFA serial
if [ -z "${MFA_SERIAL:-}" ]; then
  echo "Enter MFA serial ARN:"
  read -r MFA_SERIAL
  if [ -z "$MFA_SERIAL" ]; then
    echo "Error: MFA_SERIAL is required" >&2
    exit 1
  fi
fi
validate_input "MFA_SERIAL" "$MFA_SERIAL" "^arn:aws:iam::[0-9]{12}:mfa/.+$" 2048 "arn:aws:iam::<account-id>:mfa/<username>"

# 2.3.8 External ID (optional)
# Skip External ID prompt entirely if EXTERNAL_ID_USED is set to N
if [ "${EXTERNAL_ID_USED:-}" != "N" ]; then
  if [ -z "${EXTERNAL_ID:-}" ]; then
    echo "Enter external ID (optional, press Enter to skip):"
    read -r EXTERNAL_ID
    if [ -n "$EXTERNAL_ID" ]; then
      validate_input "EXTERNAL_ID" "$EXTERNAL_ID" "^[a-zA-Z0-9_-]+$" 1224 "alphanumeric, hyphens, underscores only"
    fi
  fi
fi

# --- 4.2 Configure role profile ---
aws configure set role_arn "$ROLE_ARN" --profile "$PROFILE"
if [ $? -ne 0 ]; then
  echo "Error: Failed to set role_arn on role profile '$PROFILE'" >&2
  exit 1
fi

aws configure set mfa_serial "$MFA_SERIAL" --profile "$PROFILE"
if [ $? -ne 0 ]; then
  echo "Error: Failed to set mfa_serial on role profile '$PROFILE'" >&2
  exit 1
fi

# 4.3 External ID only if non-empty
if [ -n "${EXTERNAL_ID:-}" ]; then
  aws configure set external_id "$EXTERNAL_ID" --profile "$PROFILE"
  if [ $? -ne 0 ]; then
    echo "Error: Failed to set external_id on role profile '$PROFILE'" >&2
    exit 1
  fi
fi

aws configure set region "$REGION" --profile "$PROFILE"
if [ $? -ne 0 ]; then
  echo "Error: Failed to set region on role profile '$PROFILE'" >&2
  exit 1
fi

aws configure set output "$OUTPUT" --profile "$PROFILE"
if [ $? -ne 0 ]; then
  echo "Error: Failed to set output on role profile '$PROFILE'" >&2
  exit 1
fi

aws configure set source_profile "$SOURCE_PROFILE" --profile "$PROFILE"
if [ $? -ne 0 ]; then
  echo "Error: Failed to set source_profile on role profile '$PROFILE'" >&2
  exit 1
fi

# 4.5 Verify profile creation (retry on MFA failure until Ctrl-C)
echo "Verifying profile creation..."
while true; do
  aws sts get-caller-identity --profile "$PROFILE"
  if [ $? -eq 0 ]; then
    break
  fi
  echo "Verification failed. To reset credentials, set RESET_CREDENTIALS=1" >&2
  echo "Retrying (Ctrl-C to abort)..." >&2
done

# 4.4 PROFILE is now set for use by calling projects
echo "Profile $PROFILE created and verified successfully."
