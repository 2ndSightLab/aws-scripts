#!/bin/bash
# Check 5: Challenge route is the only unauthenticated route

echo ""
echo "=== Check 5: Only challenge route is unauthenticated ==="

# UNAUTHENTICATED_ROUTES was populated in check-authorizer-on-routes.sh
UNAUTH_COUNT=${#UNAUTHENTICATED_ROUTES[@]}

if [ ${UNAUTH_COUNT} -eq 0 ]; then
    echo "  PASS: No unauthenticated routes found"
    return
fi

CHECK5_FAIL=0
for ROUTE in "${UNAUTHENTICATED_ROUTES[@]}"; do
    ROUTE_PATH=$(echo "${ROUTE}" | awk '{print $2}')
    if echo "${ROUTE_PATH}" | grep -qi 'challenge'; then
        echo "  OK: ${ROUTE} (challenge route - expected to be unauthenticated)"
    else
        echo "  FAIL: ${ROUTE} is unauthenticated but is NOT the challenge route"
        CHECK5_FAIL=$((CHECK5_FAIL + 1))
    fi
done

if [ ${CHECK5_FAIL} -gt 0 ]; then
    PROBLEMS_FOUND=$((PROBLEMS_FOUND + CHECK5_FAIL))
    PROBLEMS_OUTPUT+="Check 5: ${CHECK5_FAIL} non-challenge route(s) are unauthenticated\n"
else
    echo "  PASS: Only challenge route(s) are unauthenticated"
fi
