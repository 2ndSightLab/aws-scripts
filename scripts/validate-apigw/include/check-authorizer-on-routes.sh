#!/bin/bash
# Check 1: No route on the API Gateway is missing the authorizer

echo ""
echo "=== Check 1: Authorizer attached to all routes ==="

# Get all resources
RESOURCES=$(aws apigateway get-resources \
    --rest-api-id "${API_ID}" \
    --profile "${PROFILE}" \
    --region "${REGION}" \
    --output json 2>&1)
RESOURCES_RC=$?

if [ $RESOURCES_RC -ne 0 ]; then
    echo "FAIL: Could not retrieve API Gateway resources: ${RESOURCES}"
    PROBLEMS_FOUND=$((PROBLEMS_FOUND + 1))
    PROBLEMS_OUTPUT+="Check 1: Failed to retrieve resources - ${RESOURCES}\n"
    return
fi

MISSING_AUTH=0
# Extract resource IDs and paths
RESOURCE_ITEMS=$(echo "${RESOURCES}" | grep -o '"id"[[:space:]]*:[[:space:]]*"[^"]*"' | sed 's/.*"\([^"]*\)"/\1/')
RESOURCE_PATHS=$(echo "${RESOURCES}" | grep -o '"path"[[:space:]]*:[[:space:]]*"[^"]*"' | sed 's/.*"\([^"]*\)"/\1/')

mapfile -t IDS <<< "${RESOURCE_ITEMS}"
mapfile -t PATHS <<< "${RESOURCE_PATHS}"

for i in "${!IDS[@]}"; do
    RID="${IDS[$i]}"
    RPATH="${PATHS[$i]}"

    # Get methods for this resource
    METHODS=$(aws apigateway get-resource \
        --rest-api-id "${API_ID}" \
        --resource-id "${RID}" \
        --profile "${PROFILE}" \
        --region "${REGION}" \
        --output json 2>&1)

    # Extract method names (GET, POST, etc.)
    METHOD_NAMES=$(echo "${METHODS}" | grep -oE '"(GET|POST|PUT|DELETE|PATCH|OPTIONS|HEAD|ANY)"' | tr -d '"' | sort -u)

    for METHOD in ${METHOD_NAMES}; do
        METHOD_DETAIL=$(aws apigateway get-method \
            --rest-api-id "${API_ID}" \
            --resource-id "${RID}" \
            --http-method "${METHOD}" \
            --profile "${PROFILE}" \
            --region "${REGION}" \
            --output json 2>&1)

        AUTH_TYPE=$(echo "${METHOD_DETAIL}" | grep -o '"authorizationType"[[:space:]]*:[[:space:]]*"[^"]*"' | sed 's/.*"\([^"]*\)"/\1/')

        if [ "${AUTH_TYPE}" = "NONE" ]; then
            echo "  WARNING: ${METHOD} ${RPATH} has no authorizer (authorizationType=NONE)"
            UNAUTHENTICATED_ROUTES+=("${METHOD} ${RPATH}")
            MISSING_AUTH=$((MISSING_AUTH + 1))
        else
            echo "  OK: ${METHOD} ${RPATH} -> authorizationType=${AUTH_TYPE}"
        fi
    done
done

if [ ${MISSING_AUTH} -eq 0 ]; then
    echo "  PASS: All routes have an authorizer attached"
else
    echo "  FOUND ${MISSING_AUTH} route(s) without authorizer"
    PROBLEMS_FOUND=$((PROBLEMS_FOUND + MISSING_AUTH))
    PROBLEMS_OUTPUT+="Check 1: ${MISSING_AUTH} route(s) missing authorizer\n"
fi
