# --- Unexpected attached policies on execution role ---
if [ -n "${ROLE_NAME_LAMBDA}" ]; then
    EXPECTED_POLICIES="AWSLambdaBasicExecutionRole|AWSLambdaVPCAccessExecutionRole|AWSXRayDaemonWriteAccess"
    while IFS= read -r POLICY_ARN_LINE; do
        [ -z "${POLICY_ARN_LINE}" ] && continue
        POLICY_NAME_CHECK=$(echo "${POLICY_ARN_LINE}" | grep -o '"PolicyName"[[:space:]]*:[[:space:]]*"[^"]*"' | sed 's/.*"\([^"]*\)"/\1/')
        if [ -n "${POLICY_NAME_CHECK}" ] && ! echo "${POLICY_NAME_CHECK}" | grep -qE "${EXPECTED_POLICIES}"; then
            PROBLEMS_OUTPUT+="WARNING: Unexpected policy '${POLICY_NAME_CHECK}' attached to execution role '${ROLE_NAME_LAMBDA}'. Review whether this policy is needed and follows least privilege.

"
            PROBLEMS_FOUND=$((PROBLEMS_FOUND+1))
        fi
    done <<< "$(echo "${ATTACHED_POLICIES:-}" | grep -o '{[^}]*}')"
fi
