# --- NONE auth type problems ---
if [ "${AUTH_TYPE}" = "NONE" ]; then
    if [ "${HAS_RESOURCE_POLICY}" = "NO" ]; then
        PROBLEMS_OUTPUT+="PROBLEM: AuthType is NONE but NO resource-based policy exists. A resource-based policy granting lambda:InvokeFunctionUrl and lambda:InvokeFunction to Principal '*' is REQUIRED for NONE auth type.

SECURITY WARNING: AuthType NONE with Principal '*' makes this Lambda Function URL publicly accessible to ANYONE on the internet with no authentication. This means:
  - Any person or bot can invoke your function without credentials
  - You are responsible for all invocation costs from unauthorized callers
  - Your function code is the ONLY layer of defense against abuse
  - Attackers can use it for denial-of-wallet attacks (driving up your AWS bill)
  - Any data the function returns is exposed to the public

RECOMMENDED ALTERNATIVE — Option A: Function URL with AWS_IAM auth:
  1. Update the Function URL auth type to AWS_IAM:
       aws lambda update-function-url-config --function-name ${FUNCTION_NAME} --auth-type AWS_IAM --region ${REGION}
  2. Grant invoke permission to specific IAM principals (role/user) that need access:
       aws lambda add-permission --function-name ${FUNCTION_NAME} --statement-id AllowIAMInvokeURL --action lambda:InvokeFunctionUrl --principal <CALLER_ROLE_OR_USER_ARN> --function-url-auth-type AWS_IAM --region ${REGION}
       aws lambda add-permission --function-name ${FUNCTION_NAME} --statement-id AllowIAMInvokeFunction --action lambda:InvokeFunction --principal <CALLER_ROLE_OR_USER_ARN> --invoked-via-function-url --region ${REGION}
  3. Callers must sign requests with SigV4. Example with awscurl:
       awscurl --service lambda --region ${REGION} -X POST -d '{\"key\":\"value\"}' https://<url-id>.lambda-url.${REGION}.on.aws/
     Or with Python AWS SDK (botocore SigV4Auth + requests).
  Best for: service-to-service calls where the caller can sign requests.

RECOMMENDED ALTERNATIVE — Option B: API Gateway with IAM authorization:
  1. Create an HTTP API with Lambda integration:
       aws apigatewayv2 create-api --name ${FUNCTION_NAME}-api --protocol-type HTTP --target ${LAMBDA_ARN}
  2. Update the route to use IAM auth:
       aws apigatewayv2 update-route --api-id <api-id> --route-id <route-id> --authorization-type AWS_IAM
  3. Caller IAM policy needs execute-api:Invoke on the API resource.
  4. Callers sign with SigV4 against the execute-api service:
       awscurl --service execute-api --region ${REGION} -X POST https://<api-id>.execute-api.${REGION}.amazonaws.com/<path>
  Best for: APIs with multiple consumers, throttling, custom domains, or usage plans.

FOR BROWSER-BASED APPS: Browsers cannot sign requests with SigV4 natively.
  Use API Gateway or CloudFront in front, with Cognito User Pools or a Lambda authorizer for authentication.

IF YOU STILL WANT NONE AUTH TYPE (at your own risk):
  aws lambda add-permission --function-name ${FUNCTION_NAME} --statement-id FunctionURLAllowPublicAccess --action lambda:InvokeFunctionUrl --principal '*' --function-url-auth-type NONE --region ${REGION}
  aws lambda add-permission --function-name ${FUNCTION_NAME} --statement-id FunctionURLInvokeAllowPublicAccess --action lambda:InvokeFunction --principal '*' --invoked-via-function-url --region ${REGION}

"
        PROBLEMS_FOUND=$((PROBLEMS_FOUND+1))
    else
        if [ "${HAS_INVOKE_URL}" = "NO" ]; then
            PROBLEMS_OUTPUT+="PROBLEM: AuthType is NONE but resource policy does NOT grant lambda:InvokeFunctionUrl. This causes 403 Forbidden.
NOTE: Before fixing, consider the security warning below about NONE auth type.
FIX (if you accept the risk of public access):
  aws lambda add-permission --function-name ${FUNCTION_NAME} --statement-id FunctionURLAllowPublicAccess --action lambda:InvokeFunctionUrl --principal '*' --function-url-auth-type NONE --region ${REGION}

"
            PROBLEMS_FOUND=$((PROBLEMS_FOUND+1))
        fi
        if [ "${HAS_INVOKE_FUNC}" = "NO" ]; then
            PROBLEMS_OUTPUT+="PROBLEM: AuthType is NONE but resource policy does NOT grant lambda:InvokeFunction. Both permissions are required.
NOTE: Before fixing, consider the security warning below about NONE auth type.
FIX (if you accept the risk of public access):
  aws lambda add-permission --function-name ${FUNCTION_NAME} --statement-id FunctionURLInvokeAllowPublicAccess --action lambda:InvokeFunction --principal '*' --invoked-via-function-url --region ${REGION}

"
            PROBLEMS_FOUND=$((PROBLEMS_FOUND+1))
        fi
        if [ "${HAS_INVOKE_URL}" = "YES" ] && [ "${HAS_STAR_PRINCIPAL}" = "NO" ]; then
            PROBLEMS_OUTPUT+="PROBLEM: AuthType is NONE but resource policy does not grant access to Principal '*'. NONE auth type requires public access (Principal '*').

"
            PROBLEMS_FOUND=$((PROBLEMS_FOUND+1))
        fi
        if [ "${HAS_AUTH_TYPE_CONDITION}" = "YES" ] && [ "${CONDITION_AUTH_TYPE}" != "NONE" ]; then
            PROBLEMS_OUTPUT+="PROBLEM: Resource policy has FunctionUrlAuthType condition set to '${CONDITION_AUTH_TYPE}' but AuthType is NONE. Condition must match AuthType.

"
            PROBLEMS_FOUND=$((PROBLEMS_FOUND+1))
        fi
    fi
    ANALYSIS_OUTPUT+="=== SECURITY WARNING: NONE AUTH TYPE ===
AuthType NONE with Principal '*' means this Function URL is PUBLICLY ACCESSIBLE with NO authentication.
Risks: unauthorized invocations, denial-of-wallet attacks, data exposure, abuse by bots.
RECOMMENDED ALTERNATIVES:
  Option A — Function URL with AWS_IAM (service-to-service, callers sign with SigV4):
    aws lambda update-function-url-config --function-name ${FUNCTION_NAME} --auth-type AWS_IAM --region ${REGION}
  Option B — API Gateway with IAM auth (throttling, custom domains, multiple consumers):
    aws apigatewayv2 create-api --name ${FUNCTION_NAME}-api --protocol-type HTTP --target ${LAMBDA_ARN}
  Option C — Application-level auth in Lambda code (validate API key, JWT, HMAC, etc.):
    Function still runs on every request (denial-of-wallet risk remains). Suitable for one-off or low-risk functions.
  Option D — Lambda Layer for shared auth (same as C but auth logic in a reusable layer):
    Better code reuse across multiple functions, but same cost/abuse tradeoffs as Option C.
  Note: Options C/D do NOT prevent invocations or costs — only Options A/B reject callers before your code runs.
  Note: This script cannot detect application-level auth (Options C/D). If this function
  validates credentials in its handler code or via a Lambda Layer, the NONE auth type may
  be intentional. Verify with the function owner.
  For browser-based apps: use API Gateway or CloudFront with Cognito or a Lambda authorizer.

"
    if [ "${SCP_BLOCKS_NONE}" = "YES" ]; then
        PROBLEMS_OUTPUT+="PROBLEM: An SCP enforces AWS_IAM auth type only. AuthType NONE is blocked by organizational policy. Function URL with NONE auth type cannot work under this SCP.
FIX: Change AuthType to AWS_IAM, or request SCP change from organization admin.

"
        PROBLEMS_FOUND=$((PROBLEMS_FOUND+1))
    fi
fi

