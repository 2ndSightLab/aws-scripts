if [ -n "${PROBLEMS_OUTPUT}" ]; then
    ANALYSIS_OUTPUT+="════════════════════════════════════════
=== PROBLEMS FOUND WITH ${FUNCTION_NAME} ===
════════════════════════════════════════
${PROBLEMS_OUTPUT}════════════════════════════════════════

"
else
    ANALYSIS_OUTPUT+="════════════════════════════════════════
=== NO PROBLEMS DETECTED WITH ${FUNCTION_NAME} ===
════════════════════════════════════════
All checks passed. If you are still experiencing issues:
  - Verify the caller is signing requests with SigV4 (for AWS_IAM auth type)
  - Check the caller's IAM identity policy grants lambda:InvokeFunctionUrl + lambda:InvokeFunction
  - Confirm the request URL matches: $(echo "${URL_CONFIG}" | grep -o '"FunctionUrl"[[:space:]]*:[[:space:]]*"[^"]*"' | sed 's/.*"\(http[^"]*\)"/\1/')
  - Check the function code for application-level errors not caught by these checks
════════════════════════════════════════

"
fi

ANALYSIS_OUTPUT+="=== ANALYSIS SUMMARY ===
Function: ${FUNCTION_NAME}
Region: ${REGION}
Account: ${ACCOUNT_ID}
Auth Type: ${AUTH_TYPE:-NO FUNCTION URL}
Function State: ${FUNC_STATE:-UNKNOWN}
VPC: ${VPC_ID:-None}
Problems found: ${PROBLEMS_FOUND}

"

LOGS_OUTPUT+="${ANALYSIS_OUTPUT}"

# --- Troubleshooting reference ---
LOGS_OUTPUT+="=== TROUBLESHOOTING NOTES ===
If AuthType is AWS_IAM: caller must sign requests with SigV4 AND have lambda:InvokeFunctionUrl + lambda:InvokeFunction permissions.
  Use awscurl: awscurl --service lambda --region <region> -X POST https://<url-id>.lambda-url.<region>.on.aws/
  Or Python: botocore.auth.SigV4Auth to sign, then send with requests library.
If AuthType is NONE: resource policy must grant lambda:InvokeFunctionUrl + lambda:InvokeFunction to Principal '*'. WARNING: this is publicly accessible.
Cross-account AWS_IAM: resource-based policy is REQUIRED (identity policy alone is not sufficient).
Same-account AWS_IAM: either identity policy OR resource policy is sufficient.
SCPs can deny lambda:InvokeFunctionUrl even if IAM and resource policies allow it.
SCPs can enforce AWS_IAM only, blocking NONE auth type function URLs.
A 'Forbidden' with no CloudWatch logs means the request was rejected at the auth layer before reaching the function.
Browsers cannot sign requests with SigV4 — use API Gateway or CloudFront with Cognito/Lambda authorizer for browser-based access.
Alternative to Function URLs: API Gateway HTTP API with IAM auth provides throttling, custom domains, and usage plans.

"
