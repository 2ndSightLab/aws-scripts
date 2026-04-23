# --- CloudWatch Logs ---
echo "Fetching CloudWatch logs from ${LOG_GROUP}..."
CW_LOGS=$(aws logs filter-log-events \
    --log-group-name "${LOG_GROUP}" \
    --start-time "${LOOKBACK_MS}" \
    --filter-pattern "?ERROR ?Error ?error ?WARN ?Warn ?warn ?Exception ?exception ?Traceback ?traceback ?FATAL ?fatal ?CRITICAL ?critical ?TimeoutError ?denied ?Denied ?DENIED ?refused ?Refused ?timed out" \
    --limit 200 \
    --query 'events[].message' \
    --output text \
    --profile "${PROFILE}" \
    --region "${REGION}" 2>&1)
CW_RC=$?

if [ $CW_RC -eq 0 ] && [ -n "${CW_LOGS}" ]; then
    echo "  Found CloudWatch log entries."
    LOGS_OUTPUT+="=== CLOUDWATCH LOGS (last 1 hour) for ${FUNCTION_NAME} ===
${CW_LOGS}

"
else
    echo "  No CloudWatch logs found or error: ${CW_LOGS}"
    LOGS_OUTPUT+="=== CLOUDWATCH LOGS ===
No logs found or error retrieving logs: ${CW_LOGS}

"
    if [ $CW_RC -ne 0 ]; then
        PROBLEMS_OUTPUT+="PROBLEM: CloudWatch Logs not accessible for log group '${LOG_GROUP}'. Error: ${CW_LOGS}
FIX: Ensure the log group exists and the assumed role has logs:FilterLogEvents permission on '${LOG_GROUP}'.

"
        PROBLEMS_FOUND=$((PROBLEMS_FOUND+1))
    fi
fi
