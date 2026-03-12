#!/bin/bash -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
POLICY_ACTIONS=""

echo "Select an AWS CLI role to create the IAM policy"
#this script sets the PROFILE variable
source "$SCRIPT_DIR/../select-aws-cli-profile/run.sh"

# Prompt for policy name
echo ""
echo "Enter the new IAM policy name:"
while true; do
    read -p "> " POLICY_NAME
    if [[ -n "$POLICY_NAME" && "$POLICY_NAME" =~ ^[a-zA-Z0-9+=,.@_-]+$ ]]; then
        break
    fi
    echo "Invalid policy name. Use alphanumeric characters and +=,.@_-"
    echo "Enter IAM policy name:"
done

# Start policy JSON
POLICY_JSON='{"Version": "2012-10-17", "Statement": ['
FIRST_STATEMENT=true

echo "Create policy statements"
STATEMENT_COUNT=0

while true; do
    if [[ $STATEMENT_COUNT -eq 0 ]]; then
        while true; do
            read -p "Enter statement SID: " SID
            if [[ -n "$SID" ]] && [[ "$SID" =~ ^[0-9A-Za-z]*$ ]]; then
                break
            fi
            echo "SID is required and must contain only alphanumeric characters"
        done
    else
        while true; do
            read -p "Enter statement SID (or press Enter to finish): " SID
            if [[ -z "$SID" ]] || [[ "$SID" =~ ^[0-9A-Za-z]*$ ]]; then
                break
            fi
            echo "SID must contain only alphanumeric characters"
        done
    fi
    
    if [[ -z "$SID" ]]; then
        if [[ $STATEMENT_COUNT -eq 0 ]]; then
            echo "At least one statement is required."
            continue
        else
            break
        fi
    fi
    
    # Add comma if not first statement
    [[ "$FIRST_STATEMENT" = false ]] && POLICY_JSON+=','
    FIRST_STATEMENT=false
    
    # Effect
    while true; do
        read -p "Effect (Allow/Deny): " EFFECT
        if [[ "$EFFECT" =~ ^(Allow|Deny)$ ]]; then
            break
        fi
        echo "Enter 'Allow' or 'Deny'"
    done
    
    ALL_ACTIONS=()
    
    while true; do
        SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
        source "$SCRIPT_DIR/../select-actions/run.sh"
        
        if [[ -z "$ACTIONS" ]]; then
            break
        fi
        
        # Add selected actions to the overall list
        IFS=',' read -ra ACTION_ARRAY <<< "$ACTIONS"
        ALL_ACTIONS+=("${ACTION_ARRAY[@]}")
        
        read -p "Select another service? (y/n): " CONTINUE
        if [[ "$CONTINUE" != "y" ]]; then
            break
        fi
        unset SERVICE
    done
    
    # Convert all actions to JSON array
    if [[ ${#ALL_ACTIONS[@]} -gt 0 ]]; then
        ACTIONS_JSON="["
        for i in "${!ALL_ACTIONS[@]}"; do
            [[ $i -gt 0 ]] && ACTIONS_JSON+=","
            ACTIONS_JSON+="\"${ALL_ACTIONS[$i]}\""
        done
        ACTIONS_JSON+="]"
    else
        ACTIONS_JSON="[]"
    fi
    
    # Resources
    RESOURCES='['
    FIRST_RESOURCE=true
    echo "Enter resources (press Enter when done):"
    while true; do
        read -p "Resource: " RESOURCE
        [[ -z "$RESOURCE" ]] && break
        [[ "$FIRST_RESOURCE" = false ]] && RESOURCES+=','
        RESOURCES+="\"$RESOURCE\""
        FIRST_RESOURCE=false
    done
    RESOURCES+=']'
    
    # Validate at least one resource was entered
    if [[ "$RESOURCES" == "[]" ]]; then
        echo "At least one resource is required."
        continue
    fi
    
    # Build statement
    STATEMENT="{\"Sid\":\"$SID\",\"Effect\":\"$EFFECT\",\"Action\":$ACTIONS_JSON,\"Resource\":$RESOURCES}"
    POLICY_JSON+="$STATEMENT"
    STATEMENT_COUNT=$((STATEMENT_COUNT + 1))
done

POLICY_JSON+=']}'

echo "Policy JSON:"
echo "$POLICY_JSON" | jq .
echo
read -p "Create this policy? (y/n): " CREATE_CONFIRM
if [[ "$CREATE_CONFIRM" != "y" ]]; then
    echo "Policy creation cancelled."
    exit 0
fi

# Check if policy already exists
EXISTING_POLICY=$(aws iam get-policy --policy-arn "arn:aws:iam::$(aws sts get-caller-identity --query Account --output text --profile "$PROFILE" --no-cli-pager --color off):policy/$POLICY_NAME" --profile "$PROFILE" --no-cli-pager --color off 2>/dev/null)

if [[ -n "$EXISTING_POLICY" ]]; then
    read -p "Policy '$POLICY_NAME' already exists. Update it? (y/n): " UPDATE_POLICY
    if [[ "$UPDATE_POLICY" == "y" ]]; then
        echo "Updating policy..."
        POLICY_ARN="arn:aws:iam::$(aws sts get-caller-identity --query Account --output text --profile "$PROFILE" --no-cli-pager --color off):policy/$POLICY_NAME"
        aws iam create-policy-version --policy-arn "$POLICY_ARN" --policy-document "$POLICY_JSON" --set-as-default --profile "$PROFILE" --no-cli-pager --color off
    else
        echo "Policy creation cancelled."
        exit 0
    fi
else
    echo "Creating policy..."
    aws iam create-policy --policy-name "$POLICY_NAME" --policy-document "$POLICY_JSON" --profile "$PROFILE" --no-cli-pager --color off
fi

# Attach to user/role/group
echo "Attach policy to:"
echo "1) User"
echo "2) Role" 
echo "3) Group"
echo "4) None"
read -p "Select option (1-4): " ATTACH_TYPE
case "$ATTACH_TYPE" in
    1)
        read -p "Enter username: " USERNAME
        aws iam attach-user-policy --user-name "$USERNAME" --policy-arn "arn:aws:iam::$(aws sts get-caller-identity --query Account --output text --profile "$PROFILE" --no-cli-pager --color off):policy/$POLICY_NAME" --profile "$PROFILE" --no-cli-pager --color off
        ;;
    2)
        read -p "Enter role name: " ROLE_NAME
        aws iam attach-role-policy --role-name "$ROLE_NAME" --policy-arn "arn:aws:iam::$(aws sts get-caller-identity --query Account --output text --profile "$PROFILE" --no-cli-pager --color off):policy/$POLICY_NAME" --profile "$PROFILE" --no-cli-pager --color off
        ;;
    3)
        read -p "Enter group name: " GROUP_NAME
        aws iam attach-group-policy --group-name "$GROUP_NAME" --policy-arn "arn:aws:iam::$(aws sts get-caller-identity --query Account --output text --profile "$PROFILE" --no-cli-pager --color off):policy/$POLICY_NAME" --profile "$PROFILE" --no-cli-pager --color off
        ;;
esac

echo "Policy created successfully!"

