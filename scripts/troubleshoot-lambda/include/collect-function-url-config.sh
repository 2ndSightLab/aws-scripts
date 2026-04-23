# --- Function URL Configuration ---
echo "Fetching Function URL configuration..."
URL_CONFIG=$(aws lambda get-function-url-config \
    --function-name "${FUNCTION_NAME}" \
    --profile "${PROFILE}" \
    --region "${REGION}" 2>&1)
URL_RC=$?

if [ $URL_RC -eq 0 ]; then
    LOGS_OUTPUT+="=== FUNCTION URL CONFIGURATION ===
${URL_CONFIG}

"
else
    LOGS_OUTPUT+="=== FUNCTION URL CONFIGURATION ===
No Function URL or error: ${URL_CONFIG}

"
fi
