#!/bin/bash
# Check 3: SCP is in place at the OU level denying lambda:InvokeFunction except for apigateway

echo ""
echo "=== Check 3: SCP in place at OU level ==="

SCP_CHECK_FAIL=0

# Try to list org roots with current profile
ORG_ROOTS=$(aws organizations list-roots \
    --profile "${PROFILE}" \
    --region "${REGION}" 2>&1)
ORG_RC=$?

# If access denied, offer to switch to org management profile (same pattern as troubleshoot-lambda)
ORG_PROFILE="${PROFILE}"
if [ $ORG_RC -ne 0 ] && echo "${ORG_ROOTS}" | grep -q 'AccessDeniedException'; then
    echo "  AccessDeniedException on Organizations API. This requires a management account profile."
    read -r -p "  Switch to an Organizations management account profile to fetch SCPs? (y/n): " USE_ORG_PROFILE
    if [ "${USE_ORG_PROFILE}" = "y" ]; then
        SAVED_PROFILE="${PROFILE}"
        unset PROFILE
        OUTPUT="json"
        SECRETS_MANAGER_USED="N"
        EXTERNAL_ID_USED="N"
        source "${SCRIPT_DIR}/assume-role.sh"
        ORG_PROFILE="${PROFILE}"
        PROFILE="${SAVED_PROFILE}"
        unset SAVED_PROFILE

        ORG_ROOTS=$(aws organizations list-roots \
            --profile "${ORG_PROFILE}" \
            --region "${REGION}" 2>&1)
        ORG_RC=$?
    fi
fi

if [ $ORG_RC -ne 0 ]; then
    echo "  FAIL: Cannot access Organizations API: ${ORG_ROOTS}"
    PROBLEMS_FOUND=$((PROBLEMS_FOUND + 1))
    PROBLEMS_OUTPUT+="Check 3: Cannot access Organizations API to verify SCPs\n"
    return
fi

# Get SCPs for the account and parent OUs
ACCT_SCPS=$(aws organizations list-policies-for-target \
    --target-id "${ACCOUNT_ID}" \
    --filter SERVICE_CONTROL_POLICY \
    --profile "${ORG_PROFILE}" \
    --region "${REGION}" 2>&1)

PARENTS=$(aws organizations list-parents \
    --child-id "${ACCOUNT_ID}" \
    --profile "${ORG_PROFILE}" \
    --region "${REGION}" 2>&1)

# Collect all SCP IDs from account and parent OUs
ALL_SCP_IDS=""
if [ $? -eq 0 ]; then
    ALL_SCP_IDS+=$(echo "${ACCT_SCPS}" | grep -o '"Id"[[:space:]]*:[[:space:]]*"[^"]*"' | sed 's/.*"\([^"]*\)"/\1/')
    ALL_SCP_IDS+=" "

    PARENT_IDS=$(echo "${PARENTS}" | grep -o '"Id"[[:space:]]*:[[:space:]]*"[^"]*"' | sed 's/.*"\([^"]*\)"/\1/')
    for PARENT_ID in ${PARENT_IDS}; do
        PARENT_SCPS=$(aws organizations list-policies-for-target \
            --target-id "${PARENT_ID}" \
            --filter SERVICE_CONTROL_POLICY \
            --profile "${ORG_PROFILE}" \
            --region "${REGION}" 2>&1)
        ALL_SCP_IDS+=$(echo "${PARENT_SCPS}" | grep -o '"Id"[[:space:]]*:[[:space:]]*"[^"]*"' | sed 's/.*"\([^"]*\)"/\1/')
        ALL_SCP_IDS+=" "
    done
fi

# Check each SCP for a Deny on lambda:InvokeFunction with condition for apigateway
FOUND_SCP=0
for SCP_ID in ${ALL_SCP_IDS}; do
    SCP_DOC=$(aws organizations describe-policy \
        --policy-id "${SCP_ID}" \
        --profile "${ORG_PROFILE}" \
        --region "${REGION}" \
        --output json 2>&1)

    # Check if this SCP denies InvokeFunction with apigateway exception
    if echo "${SCP_DOC}" | grep -qi 'InvokeFunction' && \
       echo "${SCP_DOC}" | grep -qi 'Deny' && \
       echo "${SCP_DOC}" | grep -qi 'apigateway.amazonaws.com'; then
        echo "  FOUND: SCP ${SCP_ID} contains Deny on InvokeFunction with apigateway exception"

        # Verify it covers the backend lambda ARNs
        for FUNC_ARN in "${BACKEND_LAMBDA_ARNS[@]}"; do
            FUNC_NAME="${FUNC_ARN##*:function:}"
            if echo "${SCP_DOC}" | grep -q "${FUNC_NAME}\|${FUNC_ARN}"; then
                echo "    OK: SCP covers ${FUNC_NAME}"
            else
                echo "    WARNING: SCP may not explicitly cover ${FUNC_NAME}"
            fi
        done
        FOUND_SCP=$((FOUND_SCP + 1))
    fi
done

if [ ${FOUND_SCP} -gt 0 ]; then
    echo "  PASS: Found ${FOUND_SCP} SCP(s) denying InvokeFunction with apigateway exception"
else
    echo "  FAIL: No SCP found denying lambda:InvokeFunction with apigateway.amazonaws.com exception"
    SCP_CHECK_FAIL=1
    PROBLEMS_FOUND=$((PROBLEMS_FOUND + 1))
    PROBLEMS_OUTPUT+="Check 3: No SCP in place to deny lambda:InvokeFunction except for apigateway\n"
fi
