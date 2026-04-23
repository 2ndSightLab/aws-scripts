# --- AWS_IAM auth type problems ---
if [ "${AUTH_TYPE}" = "AWS_IAM" ]; then
    # Extract caller account from caller identity
    CALLER_ACCOUNT=$(echo "${CALLER_ID}" | grep -o '"Account"[[:space:]]*:[[:space:]]*"[^"]*"' | sed 's/.*"\([^"]*\)"/\1/')
    CALLER_ARN_VAL=$(echo "${CALLER_ID}" | grep -o '"Arn"[[:space:]]*:[[:space:]]*"[^"]*"' | sed 's/.*"\([^"]*\)"/\1/')
    IS_CROSS_ACCOUNT="NO"
    if [ -n "${CALLER_ACCOUNT}" ] && [ "${CALLER_ACCOUNT}" != "${ACCOUNT_ID}" ]; then
        IS_CROSS_ACCOUNT="YES"
    fi

    ANALYSIS_OUTPUT+="Caller account: ${CALLER_ACCOUNT:-UNKNOWN}
Lambda account: ${ACCOUNT_ID}
Cross-account: ${IS_CROSS_ACCOUNT}

"

    if [ "${IS_CROSS_ACCOUNT}" = "YES" ]; then
        # Cross-account: MUST have resource-based policy
        if [ "${HAS_INVOKE_URL}" = "NO" ]; then
            PROBLEMS_OUTPUT+="PROBLEM: Cross-account call with AWS_IAM auth. Resource policy MUST grant lambda:InvokeFunctionUrl to the calling principal. Currently missing.
FIX: Run:
  aws lambda add-permission --function-name ${FUNCTION_NAME} --statement-id CrossAccountInvokeURL --action lambda:InvokeFunctionUrl --principal ${CALLER_ACCOUNT} --function-url-auth-type AWS_IAM --region ${REGION}
  aws lambda add-permission --function-name ${FUNCTION_NAME} --statement-id CrossAccountInvokeFunction --action lambda:InvokeFunction --principal ${CALLER_ACCOUNT} --invoked-via-function-url --region ${REGION}

"
            PROBLEMS_FOUND=$((PROBLEMS_FOUND+1))
        fi
        if [ "${HAS_INVOKE_URL}" = "YES" ]; then
            # Check if the caller principal is in the policy
            if [ -n "${CALLER_ARN_VAL}" ] && ! echo "${POLICY_TEXT}" | grep -q "${CALLER_ACCOUNT}"; then
                PROBLEMS_OUTPUT+="PROBLEM: Cross-account call. Resource policy grants lambda:InvokeFunctionUrl but caller account ${CALLER_ACCOUNT} is not in the policy Principal.

"
                PROBLEMS_FOUND=$((PROBLEMS_FOUND+1))
            fi
        fi
    else
        # Same account: identity policy OR resource policy is sufficient
        if [ "${HAS_INVOKE_URL}" = "NO" ]; then
            PROBLEMS_OUTPUT+="WARNING: Same-account call with AWS_IAM auth. No resource policy grants lambda:InvokeFunctionUrl. The caller's IAM identity policy MUST grant lambda:InvokeFunctionUrl and lambda:InvokeFunction. If the caller lacks these identity permissions, this causes 403 Forbidden.
FIX (option 1 - resource policy): Run:
  aws lambda add-permission --function-name ${FUNCTION_NAME} --statement-id AllowIAMInvokeURL --action lambda:InvokeFunctionUrl --principal ${CALLER_ARN_VAL:-CALLER_ARN} --function-url-auth-type AWS_IAM --region ${REGION}
FIX (option 2 - identity policy): Attach lambda:InvokeFunctionUrl and lambda:InvokeFunction permissions to the caller's IAM role/user.

"
            PROBLEMS_FOUND=$((PROBLEMS_FOUND+1))
        fi
    fi

    if [ "${HAS_AUTH_TYPE_CONDITION}" = "YES" ] && [ "${CONDITION_AUTH_TYPE}" != "AWS_IAM" ]; then
        PROBLEMS_OUTPUT+="PROBLEM: Resource policy has FunctionUrlAuthType condition set to '${CONDITION_AUTH_TYPE}' but AuthType is AWS_IAM. Condition must match AuthType.

"
        PROBLEMS_FOUND=$((PROBLEMS_FOUND+1))
    fi

    ANALYSIS_OUTPUT+="NOTE: AWS_IAM auth requires the caller to sign requests with SigV4. A browser hitting the URL directly will NOT send SigV4 signatures and will get 403 Forbidden. Use awscurl or sign requests programmatically.

"
fi

