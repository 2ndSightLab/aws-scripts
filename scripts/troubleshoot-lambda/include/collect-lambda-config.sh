# --- Lambda Configuration ---
echo "Fetching Lambda configuration..."
LAMBDA_CONFIG=$(aws lambda get-function-configuration \
    --function-name "${FUNCTION_NAME}" \
    --profile "${PROFILE}" \
    --region "${REGION}" 2>&1)
LC_RC=$?

if [ $LC_RC -eq 0 ]; then
    LOGS_OUTPUT+="=== LAMBDA CONFIGURATION ===
${LAMBDA_CONFIG}

"
else
    LOGS_OUTPUT+="=== LAMBDA CONFIGURATION ===
Error retrieving configuration: ${LAMBDA_CONFIG}

"
fi
