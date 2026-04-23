# --- Deny checks applicable to both auth types ---
if [ "${HAS_DENY_INVOKE}" = "POSSIBLE" ]; then
    PROBLEMS_OUTPUT+="WARNING: Resource policy may contain a Deny statement affecting invoke actions. Review the full resource policy above for explicit Deny on lambda:InvokeFunctionUrl or lambda:InvokeFunction.

"
    PROBLEMS_FOUND=$((PROBLEMS_FOUND+1))
fi

if [ "${SCP_BLOCKS_INVOKE}" = "POSSIBLE" ]; then
    PROBLEMS_OUTPUT+="WARNING: An SCP may deny lambda:InvokeFunctionUrl. SCPs override all IAM and resource policies. Review the SCP policy documents above.

"
    PROBLEMS_FOUND=$((PROBLEMS_FOUND+1))
fi

# --- No Function URL configured ---
if [ $URL_RC -ne 0 ]; then
    PROBLEMS_OUTPUT+="PROBLEM: No Function URL is configured for this Lambda. The endpoint does not exist.
FIX: Create a Function URL (AWS_IAM recommended):
  aws lambda create-function-url-config --function-name ${FUNCTION_NAME} --auth-type AWS_IAM --region ${REGION}
Or with NONE auth type (publicly accessible, see security warnings above):
  aws lambda create-function-url-config --function-name ${FUNCTION_NAME} --auth-type NONE --region ${REGION}

"
    PROBLEMS_FOUND=$((PROBLEMS_FOUND+1))
fi

# --- Lambda state problems ---
FUNC_STATE=$(echo "${LAMBDA_CONFIG}" | grep -o '"State"[[:space:]]*:[[:space:]]*"[^"]*"' | head -1 | sed 's/.*"\([^"]*\)"/\1/')
FUNC_STATE_REASON=$(echo "${LAMBDA_CONFIG}" | grep -o '"StateReason"[[:space:]]*:[[:space:]]*"[^"]*"' | sed 's/.*"\([^"]*\)"/\1/')
LAST_UPDATE_STATUS=$(echo "${LAMBDA_CONFIG}" | grep -o '"LastUpdateStatus"[[:space:]]*:[[:space:]]*"[^"]*"' | sed 's/.*"\([^"]*\)"/\1/')
LAST_UPDATE_REASON=$(echo "${LAMBDA_CONFIG}" | grep -o '"LastUpdateStatusReason"[[:space:]]*:[[:space:]]*"[^"]*"' | sed 's/.*"\([^"]*\)"/\1/')

if [ -n "${FUNC_STATE}" ] && [ "${FUNC_STATE}" != "Active" ]; then
    PROBLEMS_OUTPUT+="PROBLEM: Lambda function state is '${FUNC_STATE}' (not Active). Reason: ${FUNC_STATE_REASON:-unknown}.
FIX: Resolve the issue causing the function to be in ${FUNC_STATE} state before troubleshooting the URL.

"
    PROBLEMS_FOUND=$((PROBLEMS_FOUND+1))
fi

if [ -n "${LAST_UPDATE_STATUS}" ] && [ "${LAST_UPDATE_STATUS}" = "Failed" ]; then
    PROBLEMS_OUTPUT+="PROBLEM: Last function update FAILED. Reason: ${LAST_UPDATE_REASON:-unknown}.
FIX: Resolve the failed update. The function may be running stale code or config.

"
    PROBLEMS_FOUND=$((PROBLEMS_FOUND+1))
fi

# --- Timeout from CloudWatch logs ---
if echo "${CW_LOGS}" | grep -qi 'Task timed out after'; then
    TIMEOUT_VAL=$(echo "${LAMBDA_CONFIG}" | grep -o '"Timeout"[[:space:]]*:[[:space:]]*[0-9]*' | grep -o '[0-9]*')
    PROBLEMS_OUTPUT+="PROBLEM: CloudWatch logs show 'Task timed out'. Current timeout: ${TIMEOUT_VAL:-unknown} seconds.
FIX: Increase timeout or optimize function code:
  aws lambda update-function-configuration --function-name ${FUNCTION_NAME} --timeout <seconds> --region ${REGION}

"
    PROBLEMS_FOUND=$((PROBLEMS_FOUND+1))
fi

# --- Out of memory from CloudWatch logs ---
if echo "${CW_LOGS}" | grep -qi 'Runtime.ExitError\|Cannot allocate memory\|Runtime exited.*signal\|out of memory\|SIGKILL'; then
    MEM_VAL=$(echo "${LAMBDA_CONFIG}" | grep -o '"MemorySize"[[:space:]]*:[[:space:]]*[0-9]*' | grep -o '[0-9]*')
    PROBLEMS_OUTPUT+="PROBLEM: CloudWatch logs suggest out-of-memory or runtime crash. Current memory: ${MEM_VAL:-unknown} MB.
FIX: Increase memory:
  aws lambda update-function-configuration --function-name ${FUNCTION_NAME} --memory-size <MB> --region ${REGION}

"
    PROBLEMS_FOUND=$((PROBLEMS_FOUND+1))
fi

# --- Permission denied in CloudWatch logs (function's own execution role) ---
if echo "${CW_LOGS}" | grep -qi 'AccessDeniedException\|is not authorized to perform\|Access Denied'; then
    PROBLEMS_OUTPUT+="PROBLEM: CloudWatch logs show access denied errors during function execution. The Lambda execution role (${ROLE_ARN_LAMBDA:-unknown}) lacks permissions for AWS services the function is calling.
FIX: Review the errors above in CLOUDWATCH LOGS and add the required permissions to the execution role '${ROLE_NAME_LAMBDA:-unknown}'.

"
    PROBLEMS_FOUND=$((PROBLEMS_FOUND+1))
fi

# --- VPC connectivity: rejected flow logs found ---
if [ -n "${VPC_ID}" ] && [ -n "${FLOW_LOGS:-}" ] && echo "${FLOW_LOGS}" | grep -qi 'REJECT'; then
    PROBLEMS_OUTPUT+="PROBLEM: Lambda is in VPC ${VPC_ID} and VPC flow logs show REJECTED traffic from Lambda ENIs. The function cannot reach its target.
FIX: Check that:
  - Security groups allow outbound traffic to the required destination/port
  - Subnet route table has a NAT Gateway route (for internet access) or VPC endpoints (for AWS services)
  - NACLs allow the traffic

"
    PROBLEMS_FOUND=$((PROBLEMS_FOUND+1))
fi

# --- VPC with no NAT/endpoint warning ---
if [ -n "${VPC_ID}" ]; then
    # Check if security groups have no outbound rules
    if [ -n "${SG_RULES:-}" ] && ! echo "${SG_RULES}" | grep -q '"IpProtocol"'; then
        PROBLEMS_OUTPUT+="PROBLEM: Lambda security groups in VPC ${VPC_ID} appear to have no outbound rules. The function cannot make any outbound connections.
FIX: Add outbound rules to the security group(s): ${SG_IDS:-unknown}

"
        PROBLEMS_FOUND=$((PROBLEMS_FOUND+1))
    fi
fi

# --- CORS issues (Function URL) ---
if [ $URL_RC -eq 0 ]; then
    CORS_CONFIG=$(echo "${URL_CONFIG}" | grep -o '"Cors"[[:space:]]*:[[:space:]]*{[^}]*}')
    if [ -z "${CORS_CONFIG}" ]; then
        PROBLEMS_OUTPUT+="WARNING: Function URL has no CORS configuration. Browser-based requests from other origins will fail with CORS errors.
FIX (if browser access is needed):
  aws lambda update-function-url-config --function-name ${FUNCTION_NAME} --cors '{\"AllowOrigins\":[\"https://yourdomain.com\"],\"AllowMethods\":[\"POST\",\"GET\"],\"AllowHeaders\":[\"content-type\"]}' --region ${REGION}

"
        PROBLEMS_FOUND=$((PROBLEMS_FOUND+1))
    fi
fi

# --- Reserved concurrency check ---
RESERVED_CONCURRENCY=$(echo "${LAMBDA_CONFIG}" | grep -o '"ReservedConcurrentExecutions"[[:space:]]*:[[:space:]]*[0-9]*' | grep -o '[0-9]*')
if [ -z "${RESERVED_CONCURRENCY}" ]; then
    PROBLEMS_OUTPUT+="WARNING: No reserved concurrency configured. This function shares the account's unreserved concurrency pool and may be throttled by other functions, or may consume concurrency needed by other functions.
FIX: Set reserved concurrency:
  aws lambda put-function-concurrency --function-name ${FUNCTION_NAME} --reserved-concurrent-executions <number> --region ${REGION}
NOTE: Check your account concurrency quota first:
  aws lambda get-account-settings --region ${REGION} --query 'AccountLimit.ConcurrentExecutions'

"
    PROBLEMS_FOUND=$((PROBLEMS_FOUND+1))
fi
