# --- CloudTrail Events ---
echo "Fetching CloudTrail events for ${FUNCTION_NAME}..."
START_TIME=$(date -u -d '1 hour ago' '+%Y-%m-%dT%H:%M:%SZ' 2>/dev/null || date -u -v-1H '+%Y-%m-%dT%H:%M:%SZ')
CT_LOGS=$(aws cloudtrail lookup-events \
    --lookup-attributes "AttributeKey=ResourceName,AttributeValue=${LAMBDA_ARN}" \
    --start-time "${START_TIME}" \
    --max-results 50 \
    --query 'Events[?contains(CloudTrailEvent,`errorCode`)].CloudTrailEvent' \
    --output text \
    --profile "${PROFILE}" \
    --region "${REGION}" 2>&1)
CT_RC=$?

if [ $CT_RC -eq 0 ] && [ -n "${CT_LOGS}" ]; then
    echo "  Found CloudTrail events."
    LOGS_OUTPUT+="=== CLOUDTRAIL EVENTS (last 1 hour) for ${FUNCTION_NAME} ===
${CT_LOGS}

"
else
    echo "  No CloudTrail events found or error: ${CT_LOGS}"
    LOGS_OUTPUT+="=== CLOUDTRAIL EVENTS ===
No events found or error retrieving events: ${CT_LOGS}

"
fi
