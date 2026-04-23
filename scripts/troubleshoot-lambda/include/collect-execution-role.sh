# --- Lambda Execution Role Permissions ---
echo "Fetching Lambda execution role details..."
ROLE_ARN_LAMBDA=$(echo "${LAMBDA_CONFIG}" | grep -o '"Role"[[:space:]]*:[[:space:]]*"[^"]*"' | sed 's/.*"Role"[[:space:]]*:[[:space:]]*"\([^"]*\)"/\1/')
if [ -n "${ROLE_ARN_LAMBDA}" ]; then
    ROLE_NAME_LAMBDA="${ROLE_ARN_LAMBDA##*/}"
    ROLE_DETAILS=$(aws iam get-role \
        --role-name "${ROLE_NAME_LAMBDA}" \
        --profile "${PROFILE}" \
        --region "${REGION}" 2>&1)
    LOGS_OUTPUT+="=== LAMBDA EXECUTION ROLE ===
${ROLE_DETAILS}

"
    # Inline policies
    INLINE_POLICIES=$(aws iam list-role-policies \
        --role-name "${ROLE_NAME_LAMBDA}" \
        --profile "${PROFILE}" \
        --region "${REGION}" 2>&1)
    LOGS_OUTPUT+="=== EXECUTION ROLE INLINE POLICY NAMES ===
${INLINE_POLICIES}

"
    # Get each inline policy document
    POLICY_NAMES=$(aws iam list-role-policies \
        --role-name "${ROLE_NAME_LAMBDA}" \
        --query 'PolicyNames[]' \
        --output text \
        --profile "${PROFILE}" \
        --region "${REGION}" 2>/dev/null)
    for PNAME in ${POLICY_NAMES}; do
        PDOC=$(aws iam get-role-policy \
            --role-name "${ROLE_NAME_LAMBDA}" \
            --policy-name "${PNAME}" \
            --profile "${PROFILE}" \
            --region "${REGION}" 2>&1)
        LOGS_OUTPUT+="=== INLINE POLICY: ${PNAME} ===
${PDOC}

"
    done

    # Attached managed policies
    ATTACHED_POLICIES=$(aws iam list-attached-role-policies \
        --role-name "${ROLE_NAME_LAMBDA}" \
        --profile "${PROFILE}" \
        --region "${REGION}" 2>&1)
    LOGS_OUTPUT+="=== EXECUTION ROLE ATTACHED POLICIES ===
${ATTACHED_POLICIES}

"
else
    LOGS_OUTPUT+="=== LAMBDA EXECUTION ROLE ===
Could not extract role ARN from Lambda configuration.

"
fi
