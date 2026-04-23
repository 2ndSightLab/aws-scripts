#!/bin/bash
# Check 4: Authorizer cache TTL is 0

echo ""
echo "=== Check 4: Authorizer cache TTL is 0 ==="

AUTHORIZERS=$(aws apigateway get-authorizers \
    --rest-api-id "${API_ID}" \
    --profile "${PROFILE}" \
    --region "${REGION}" \
    --output json 2>&1)
AUTH_RC=$?

if [ $AUTH_RC -ne 0 ]; then
    echo "  FAIL: Could not retrieve authorizers: ${AUTHORIZERS}"
    PROBLEMS_FOUND=$((PROBLEMS_FOUND + 1))
    PROBLEMS_OUTPUT+="Check 4: Failed to retrieve authorizers\n"
    return
fi

AUTH_COUNT=$(echo "${AUTHORIZERS}" | grep -o '"id"' | wc -l)
if [ "${AUTH_COUNT}" -eq 0 ]; then
    echo "  FAIL: No authorizers found on API ${API_ID}"
    PROBLEMS_FOUND=$((PROBLEMS_FOUND + 1))
    PROBLEMS_OUTPUT+="Check 4: No authorizers configured\n"
    return
fi

TTL_FAIL=0
AUTH_IDS=$(echo "${AUTHORIZERS}" | grep -o '"id"[[:space:]]*:[[:space:]]*"[^"]*"' | sed 's/.*"\([^"]*\)"/\1/')
AUTH_NAMES=$(echo "${AUTHORIZERS}" | grep -o '"name"[[:space:]]*:[[:space:]]*"[^"]*"' | sed 's/.*"\([^"]*\)"/\1/')

mapfile -t A_IDS <<< "${AUTH_IDS}"
mapfile -t A_NAMES <<< "${AUTH_NAMES}"

for i in "${!A_IDS[@]}"; do
    TTL=$(echo "${AUTHORIZERS}" | grep -A5 "\"id\"[[:space:]]*:[[:space:]]*\"${A_IDS[$i]}\"" | grep -o '"authorizerResultTtlInSeconds"[[:space:]]*:[[:space:]]*[0-9]*' | grep -o '[0-9]*$')
    TTL="${TTL:-not set}"

    if [ "${TTL}" = "0" ]; then
        echo "  OK: Authorizer '${A_NAMES[$i]}' TTL=${TTL}"
    else
        echo "  FAIL: Authorizer '${A_NAMES[$i]}' TTL=${TTL} (expected 0)"
        TTL_FAIL=$((TTL_FAIL + 1))
    fi
done

if [ ${TTL_FAIL} -gt 0 ]; then
    PROBLEMS_FOUND=$((PROBLEMS_FOUND + TTL_FAIL))
    PROBLEMS_OUTPUT+="Check 4: ${TTL_FAIL} authorizer(s) with non-zero cache TTL\n"
else
    echo "  PASS: All authorizer cache TTLs are 0"
fi
