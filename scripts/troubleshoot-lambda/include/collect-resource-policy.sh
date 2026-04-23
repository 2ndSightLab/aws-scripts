# --- Resource-Based Policy ---
echo "Fetching Lambda resource policy..."
RESOURCE_POLICY=$(aws lambda get-policy \
    --function-name "${FUNCTION_NAME}" \
    --profile "${PROFILE}" \
    --region "${REGION}" 2>&1)
RP_RC=$?

if [ $RP_RC -eq 0 ]; then
    LOGS_OUTPUT+="=== RESOURCE-BASED POLICY ===
${RESOURCE_POLICY}

"
else
    LOGS_OUTPUT+="=== RESOURCE-BASED POLICY ===
No resource policy or error: ${RESOURCE_POLICY}

"
fi
