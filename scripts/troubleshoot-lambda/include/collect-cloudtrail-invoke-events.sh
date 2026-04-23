# --- CloudTrail: lambda:InvokeFunctionUrl denied events ---
echo "Fetching CloudTrail access denied events for InvokeFunctionUrl..."
CT_INVOKE_LOGS=$(aws cloudtrail lookup-events \
    --lookup-attributes "AttributeKey=EventName,AttributeValue=InvokeFunctionUrl" \
    --start-time "${START_TIME}" \
    --max-results 50 \
    --query 'Events[?contains(CloudTrailEvent,`errorCode`)].CloudTrailEvent' \
    --output text \
    --profile "${PROFILE}" \
    --region "${REGION}" 2>&1)
CT_INVOKE_RC=$?

if [ $CT_INVOKE_RC -eq 0 ] && [ -n "${CT_INVOKE_LOGS}" ]; then
    LOGS_OUTPUT+="=== CLOUDTRAIL InvokeFunctionUrl EVENTS (last 1 hour) ===
${CT_INVOKE_LOGS}

"
else
    LOGS_OUTPUT+="=== CLOUDTRAIL InvokeFunctionUrl EVENTS ===
No InvokeFunctionUrl events found or error: ${CT_INVOKE_LOGS}

"
fi

# --- Check if CloudTrail is logging Lambda data events ---
echo "Checking CloudTrail trails for Lambda data event logging..."
TRAILS=$(aws cloudtrail describe-trails \
    --query 'trailList[].TrailARN' \
    --output text \
    --profile "${PROFILE}" \
    --region "${REGION}" 2>&1)
LAMBDA_DATA_EVENTS_ENABLED="NO"
if [ $? -eq 0 ] && [ -n "${TRAILS}" ]; then
    for TRAIL_ARN in ${TRAILS}; do
        ES=$(aws cloudtrail get-event-selectors \
            --trail-name "${TRAIL_ARN}" \
            --profile "${PROFILE}" \
            --region "${REGION}" 2>&1)
        if echo "${ES}" | grep -q '"AWS::Lambda::Function"'; then
            LAMBDA_DATA_EVENTS_ENABLED="YES"
            break
        fi
    done
fi
LOGS_OUTPUT+="=== CLOUDTRAIL LAMBDA DATA EVENTS ENABLED ===
${LAMBDA_DATA_EVENTS_ENABLED}

"
if [ "${LAMBDA_DATA_EVENTS_ENABLED}" = "NO" ]; then
    LOGS_OUTPUT+="WARNING: No CloudTrail trail is logging Lambda data events. InvokeFunctionUrl is a data event and will NOT appear in CloudTrail without this enabled.

"
fi
