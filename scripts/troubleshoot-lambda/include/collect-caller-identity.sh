# --- Caller Identity ---
echo "Fetching caller identity..."
CALLER_ID=$(aws sts get-caller-identity \
    --profile "${PROFILE}" \
    --region "${REGION}" 2>&1)
LOGS_OUTPUT+="=== CALLER IDENTITY ===
${CALLER_ID}

"
