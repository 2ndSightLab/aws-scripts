#!/usr/bin/env bash
# Validate API Gateway configuration per README requirements
set -uo pipefail

SCRIPT_DIR="$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")"
INCLUDE_DIR="${SCRIPT_DIR}/include"

echo ""
echo "========================================"
echo "     Validate API Gateway Configuration"
echo "========================================"
echo ""

# --- Prompt for API Gateway REST API ID ---
read -r -p "Enter API Gateway REST API ID: " API_ID
if [ -z "${API_ID}" ]; then echo "ERROR: API ID is required" >&2; exit 1; fi

# --- Prompt for backend Lambda ARNs ---
BACKEND_LAMBDA_ARNS=()
echo "Enter backend Lambda ARNs (one per line, empty line to finish):"
while true; do
    read -r -p "  Lambda ARN: " LARN
    if [ -z "${LARN}" ]; then break; fi
    if ! echo "${LARN}" | grep -qE '^arn:aws:lambda:[a-z0-9-]+:[0-9]{12}:function:.+$'; then
        echo "ERROR: Invalid Lambda ARN format" >&2; exit 1
    fi
    BACKEND_LAMBDA_ARNS+=("${LARN}")
done

if [ ${#BACKEND_LAMBDA_ARNS[@]} -eq 0 ]; then
    echo "ERROR: At least one backend Lambda ARN is required" >&2; exit 1
fi

# Extract region and account from first Lambda ARN
REGION="$(echo "${BACKEND_LAMBDA_ARNS[0]}" | cut -d: -f4)"
ACCOUNT_ID="$(echo "${BACKEND_LAMBDA_ARNS[0]}" | cut -d: -f5)"

echo ""
echo "API ID:   ${API_ID}"
echo "Region:   ${REGION}"
echo "Account:  ${ACCOUNT_ID}"
echo "Lambdas:  ${#BACKEND_LAMBDA_ARNS[@]}"
echo ""

# --- Assume role using local copy of assume-role.sh ---
OUTPUT="json"
SECRETS_MANAGER_USED="N"
EXTERNAL_ID_USED="N"
RESET_CREDENTIALS="${RESET_CREDENTIALS:-0}"

source "${SCRIPT_DIR}/assume-role.sh"
RC=$?
if [ $RC -ne 0 ]; then echo "ERROR: Failed to assume role" >&2; exit 1; fi

echo ""
echo "========================================"
echo "       Running Validation Checks"
echo "========================================"

PROBLEMS_FOUND=0
PROBLEMS_OUTPUT=""
UNAUTHENTICATED_ROUTES=()

source "${INCLUDE_DIR}/check-authorizer-on-routes.sh"
source "${INCLUDE_DIR}/check-lambda-invoke-grants.sh"
source "${INCLUDE_DIR}/check-scp.sh"
source "${INCLUDE_DIR}/check-authorizer-ttl.sh"
source "${INCLUDE_DIR}/check-challenge-route.sh"
source "${INCLUDE_DIR}/check-dangerous-permissions.sh"

echo ""
echo "========================================"
echo "       Validation Summary"
echo "========================================"
echo ""

if [ ${PROBLEMS_FOUND} -eq 0 ]; then
    echo "ALL CHECKS PASSED"
else
    echo "PROBLEMS FOUND: ${PROBLEMS_FOUND}"
    echo ""
    echo -e "${PROBLEMS_OUTPUT}"
fi
