# --- SCPs: Check Organizations policies that may deny lambda:InvokeFunctionUrl ---
echo "Fetching SCPs (Service Control Policies)..."
SCP_OUTPUT=""

# List roots to find org structure
ORG_ROOTS=$(aws organizations list-roots \
    --profile "${PROFILE}" \
    --region "${REGION}" 2>&1)
ORG_RC=$?

if [ $ORG_RC -eq 0 ]; then
    SCP_OUTPUT+="=== ORGANIZATION ROOTS ===
${ORG_ROOTS}

"
    # Get SCPs for the account
    ACCT_SCPS=$(aws organizations list-policies-for-target \
        --target-id "${ACCOUNT_ID}" \
        --filter SERVICE_CONTROL_POLICY \
        --profile "${PROFILE}" \
        --region "${REGION}" 2>&1)
    ACCT_SCPS_RC=$?

    if [ $ACCT_SCPS_RC -eq 0 ]; then
        SCP_OUTPUT+="=== SCPs ATTACHED TO ACCOUNT ${ACCOUNT_ID} ===
${ACCT_SCPS}

"
        # Get each SCP document
        SCP_IDS=$(echo "${ACCT_SCPS}" | grep -o '"Id"[[:space:]]*:[[:space:]]*"[^"]*"' | sed 's/.*"Id"[[:space:]]*:[[:space:]]*"\([^"]*\)"/\1/')
        for SCP_ID in ${SCP_IDS}; do
            SCP_DOC=$(aws organizations describe-policy \
                --policy-id "${SCP_ID}" \
                --profile "${PROFILE}" \
                --region "${REGION}" 2>&1)
            SCP_OUTPUT+="=== SCP POLICY: ${SCP_ID} ===
${SCP_DOC}

"
        done
    else
        SCP_OUTPUT+="=== SCPs FOR ACCOUNT ===
Could not list SCPs for account: ${ACCT_SCPS}

"
    fi

    # Also get SCPs from parent OUs
    PARENTS=$(aws organizations list-parents \
        --child-id "${ACCOUNT_ID}" \
        --profile "${PROFILE}" \
        --region "${REGION}" 2>&1)
    PARENTS_RC=$?

    if [ $PARENTS_RC -eq 0 ]; then
        SCP_OUTPUT+="=== ACCOUNT PARENTS ===
${PARENTS}

"
        PARENT_IDS=$(echo "${PARENTS}" | grep -o '"Id"[[:space:]]*:[[:space:]]*"[^"]*"' | sed 's/.*"Id"[[:space:]]*:[[:space:]]*"\([^"]*\)"/\1/')
        for PARENT_ID in ${PARENT_IDS}; do
            PARENT_SCPS=$(aws organizations list-policies-for-target \
                --target-id "${PARENT_ID}" \
                --filter SERVICE_CONTROL_POLICY \
                --profile "${PROFILE}" \
                --region "${REGION}" 2>&1)
            SCP_OUTPUT+="=== SCPs ON PARENT ${PARENT_ID} ===
${PARENT_SCPS}

"
            PARENT_SCP_IDS=$(echo "${PARENT_SCPS}" | grep -o '"Id"[[:space:]]*:[[:space:]]*"[^"]*"' | sed 's/.*"Id"[[:space:]]*:[[:space:]]*"\([^"]*\)"/\1/')
            for PSCP_ID in ${PARENT_SCP_IDS}; do
                PSCP_DOC=$(aws organizations describe-policy \
                    --policy-id "${PSCP_ID}" \
                    --profile "${PROFILE}" \
                    --region "${REGION}" 2>&1)
                SCP_OUTPUT+="=== SCP POLICY: ${PSCP_ID} (from parent ${PARENT_ID}) ===
${PSCP_DOC}

"
            done
        done
    fi
else
    # Check if this is an AccessDeniedException — offer to switch to an Org management profile
    ORG_PROFILE=""
    if echo "${ORG_ROOTS}" | grep -q 'AccessDeniedException'; then
        echo ""
        echo "AccessDeniedException on Organizations API. This requires a management account profile."
        read -r -p "Switch to an Organizations management account profile to fetch SCPs? (y/n): " USE_ORG_PROFILE
        if [ "${USE_ORG_PROFILE}" = "y" ]; then
            # Save current profile and source assume-role for Org profile
            SAVED_PROFILE="${PROFILE}"
            unset PROFILE
            OUTPUT="json"
            SECRETS_MANAGER_USED="N"
            EXTERNAL_ID_USED="N"
            source "${SCRIPT_DIR}/assume-role.sh"
            ORG_PROFILE="${PROFILE}"
            # Restore original profile
            PROFILE="${SAVED_PROFILE}"
            unset SAVED_PROFILE
        fi
    fi

    if [ -n "${ORG_PROFILE}" ]; then
        # Retry Organizations commands with the Org management profile
        ORG_ROOTS=$(aws organizations list-roots \
            --profile "${ORG_PROFILE}" \
            --region "${REGION}" 2>&1)
        ORG_RC=$?

        if [ $ORG_RC -eq 0 ]; then
            SCP_OUTPUT+="=== ORGANIZATION ROOTS ===
${ORG_ROOTS}

"
            ACCT_SCPS=$(aws organizations list-policies-for-target \
                --target-id "${ACCOUNT_ID}" \
                --filter SERVICE_CONTROL_POLICY \
                --profile "${ORG_PROFILE}" \
                --region "${REGION}" 2>&1)
            ACCT_SCPS_RC=$?

            if [ $ACCT_SCPS_RC -eq 0 ]; then
                SCP_OUTPUT+="=== SCPs ATTACHED TO ACCOUNT ${ACCOUNT_ID} ===
${ACCT_SCPS}

"
                SCP_IDS=$(echo "${ACCT_SCPS}" | grep -o '"Id"[[:space:]]*:[[:space:]]*"[^"]*"' | sed 's/.*"Id"[[:space:]]*:[[:space:]]*"\([^"]*\)"/\1/')
                for SCP_ID in ${SCP_IDS}; do
                    SCP_DOC=$(aws organizations describe-policy \
                        --policy-id "${SCP_ID}" \
                        --profile "${ORG_PROFILE}" \
                        --region "${REGION}" 2>&1)
                    SCP_OUTPUT+="=== SCP POLICY: ${SCP_ID} ===
${SCP_DOC}

"
                done
            else
                SCP_OUTPUT+="=== SCPs FOR ACCOUNT ===
Could not list SCPs for account: ${ACCT_SCPS}

"
            fi

            PARENTS=$(aws organizations list-parents \
                --child-id "${ACCOUNT_ID}" \
                --profile "${ORG_PROFILE}" \
                --region "${REGION}" 2>&1)
            PARENTS_RC=$?

            if [ $PARENTS_RC -eq 0 ]; then
                SCP_OUTPUT+="=== ACCOUNT PARENTS ===
${PARENTS}

"
                PARENT_IDS=$(echo "${PARENTS}" | grep -o '"Id"[[:space:]]*:[[:space:]]*"[^"]*"' | sed 's/.*"Id"[[:space:]]*:[[:space:]]*"\([^"]*\)"/\1/')
                for PARENT_ID in ${PARENT_IDS}; do
                    PARENT_SCPS=$(aws organizations list-policies-for-target \
                        --target-id "${PARENT_ID}" \
                        --filter SERVICE_CONTROL_POLICY \
                        --profile "${ORG_PROFILE}" \
                        --region "${REGION}" 2>&1)
                    SCP_OUTPUT+="=== SCPs ON PARENT ${PARENT_ID} ===
${PARENT_SCPS}

"
                    PARENT_SCP_IDS=$(echo "${PARENT_SCPS}" | grep -o '"Id"[[:space:]]*:[[:space:]]*"[^"]*"' | sed 's/.*"Id"[[:space:]]*:[[:space:]]*"\([^"]*\)"/\1/')
                    for PSCP_ID in ${PARENT_SCP_IDS}; do
                        PSCP_DOC=$(aws organizations describe-policy \
                            --policy-id "${PSCP_ID}" \
                            --profile "${ORG_PROFILE}" \
                            --region "${REGION}" 2>&1)
                        SCP_OUTPUT+="=== SCP POLICY: ${PSCP_ID} (from parent ${PARENT_ID}) ===
${PSCP_DOC}

"
                    done
                done
            fi
        else
            SCP_OUTPUT+="=== ORGANIZATION/SCPs ===
Not an Organizations management account or no access: ${ORG_ROOTS}

"
        fi
    else
        SCP_OUTPUT+="=== ORGANIZATION/SCPs ===
Not an Organizations management account or no access: ${ORG_ROOTS}

"
    fi
fi

LOGS_OUTPUT+="${SCP_OUTPUT}"
