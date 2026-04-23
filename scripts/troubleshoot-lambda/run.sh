#!/usr/bin/env bash
# Troubleshoot a Lambda function by collecting CloudWatch and CloudTrail logs
# then sending them to Kiro CLI agent for error analysis and recommendations.
set -uo pipefail

SCRIPT_DIR="$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")"
INCLUDE_DIR="${SCRIPT_DIR}/include"

echo ""
echo "========================================"
echo "       Troubleshoot Lambda Function"
echo "========================================"
echo ""

# --- Prompt for Lambda ARN ---
read -r -p "Enter Lambda function ARN: " LAMBDA_ARN
if [ -z "${LAMBDA_ARN}" ]; then echo "ERROR: Lambda ARN is required" >&2; exit 1; fi

# Validate ARN format
if ! echo "${LAMBDA_ARN}" | grep -qE '^arn:aws:lambda:[a-z0-9-]+:[0-9]{12}:function:.+$'; then
    echo "ERROR: Invalid Lambda ARN format" >&2; exit 1
fi

# Extract function name, region, and account ID from ARN
FUNCTION_NAME="${LAMBDA_ARN##*:function:}"
REGION="$(echo "${LAMBDA_ARN}" | cut -d: -f4)"
ACCOUNT_ID="$(echo "${LAMBDA_ARN}" | cut -d: -f5)"

echo "Function: ${FUNCTION_NAME}"
echo "Region:   ${REGION}"
echo "Account:  ${ACCOUNT_ID}"
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
echo "       Collecting Logs"
echo "========================================"
echo ""

PROBLEMS_FOUND=0
PROBLEMS_OUTPUT=""
LOG_GROUP="/aws/lambda/${FUNCTION_NAME}"
LOOKBACK_MS=$(( $(date +%s) * 1000 - 3600000 ))
LOGS_OUTPUT=""

source "${INCLUDE_DIR}/collect-cloudwatch-logs.sh"
source "${INCLUDE_DIR}/collect-cloudtrail-events.sh"
source "${INCLUDE_DIR}/collect-lambda-config.sh"
source "${INCLUDE_DIR}/collect-vpc-data.sh"
source "${INCLUDE_DIR}/collect-function-url-config.sh"
source "${INCLUDE_DIR}/collect-resource-policy.sh"
source "${INCLUDE_DIR}/collect-execution-role.sh"
source "${INCLUDE_DIR}/collect-caller-identity.sh"
source "${INCLUDE_DIR}/collect-scps.sh"
source "${INCLUDE_DIR}/collect-cloudtrail-invoke-events.sh"
source "${INCLUDE_DIR}/analyze-auth-config.sh"
source "${INCLUDE_DIR}/analyze-auth-none.sh"
source "${INCLUDE_DIR}/analyze-auth-iam.sh"
source "${INCLUDE_DIR}/analyze-common-problems.sh"
source "${INCLUDE_DIR}/collect-vpc-networking.sh"
source "${INCLUDE_DIR}/analyze-role-policies.sh"
source "${INCLUDE_DIR}/check-custom-domain-resolution.sh"
source "${INCLUDE_DIR}/build-analysis-summary.sh"
source "${INCLUDE_DIR}/select-agent-and-send.sh"
