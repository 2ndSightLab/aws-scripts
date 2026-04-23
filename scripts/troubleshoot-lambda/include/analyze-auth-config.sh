# --- Deterministic Function URL auth analysis ---
echo "Analyzing Function URL auth configuration..."
AUTH_TYPE=$(echo "${URL_CONFIG}" | grep -o '"AuthType"[[:space:]]*:[[:space:]]*"[^"]*"' | sed 's/.*"\([^"]*\)"/\1/')
ANALYSIS_OUTPUT=""

# Parse resource policy into a flat string for checking
POLICY_TEXT=""
if [ $RP_RC -eq 0 ]; then
    POLICY_TEXT="${RESOURCE_POLICY}"
fi

# Check 1: Does resource policy exist at all?
HAS_RESOURCE_POLICY="NO"
if [ -n "${POLICY_TEXT}" ]; then
    HAS_RESOURCE_POLICY="YES"
fi

# Check 2: Does resource policy grant lambda:InvokeFunctionUrl?
HAS_INVOKE_URL="NO"
if echo "${POLICY_TEXT}" | grep -qi 'lambda:InvokeFunctionUrl'; then
    HAS_INVOKE_URL="YES"
fi

# Check 3: Does resource policy grant lambda:InvokeFunction?
HAS_INVOKE_FUNC="NO"
if echo "${POLICY_TEXT}" | grep -qi 'lambda:InvokeFunction"' && ! echo "${POLICY_TEXT}" | grep -qi 'lambda:InvokeFunctionUrl'; then
    HAS_INVOKE_FUNC="YES"
fi

# Check 4: Does resource policy have Principal "*" (public access)?
HAS_STAR_PRINCIPAL="NO"
if echo "${POLICY_TEXT}" | grep -qE '"Principal"[[:space:]]*:[[:space:]]*"\*"'; then
    HAS_STAR_PRINCIPAL="YES"
fi

# Check 5: Does resource policy have an Allow effect?
HAS_ALLOW="NO"
if echo "${POLICY_TEXT}" | grep -qi '"Effect"[[:space:]]*:[[:space:]]*"Allow"'; then
    HAS_ALLOW="YES"
fi

# Check 6: Does resource policy have a Deny that blocks invocation?
HAS_DENY_INVOKE="NO"
if echo "${POLICY_TEXT}" | grep -qi '"Effect"[[:space:]]*:[[:space:]]*"Deny"'; then
    if echo "${POLICY_TEXT}" | grep -qi 'lambda:InvokeFunctionUrl\|lambda:InvokeFunction\|lambda:\*'; then
        HAS_DENY_INVOKE="POSSIBLE"
    fi
fi

# Check 7: FunctionUrlAuthType condition matches AuthType?
HAS_AUTH_TYPE_CONDITION="NO"
CONDITION_AUTH_TYPE=""
if echo "${POLICY_TEXT}" | grep -q 'lambda:FunctionUrlAuthType'; then
    HAS_AUTH_TYPE_CONDITION="YES"
    CONDITION_AUTH_TYPE=$(echo "${POLICY_TEXT}" | grep -o '"lambda:FunctionUrlAuthType"[[:space:]]*:[[:space:]]*"[^"]*"' | sed 's/.*"\([^"]*\)"/\1/')
fi

# Check 8: SCP denying lambda:InvokeFunctionUrl or lambda:CreateFunctionUrlConfig with NONE?
SCP_BLOCKS_INVOKE="NO"
SCP_BLOCKS_NONE="NO"
if echo "${SCP_OUTPUT}" | grep -qi 'lambda:InvokeFunctionUrl'; then
    if echo "${SCP_OUTPUT}" | grep -qi '"Effect"[[:space:]]*:[[:space:]]*"Deny"'; then
        SCP_BLOCKS_INVOKE="POSSIBLE"
    fi
fi
if echo "${SCP_OUTPUT}" | grep -qi 'lambda:CreateFunctionUrlConfig\|lambda:UpdateFunctionUrlConfig'; then
    if echo "${SCP_OUTPUT}" | grep -qi 'StringNotEquals.*lambda:FunctionUrlAuthType.*AWS_IAM\|StringEquals.*lambda:FunctionUrlAuthType.*NONE'; then
        SCP_BLOCKS_NONE="YES"
    fi
fi

ANALYSIS_OUTPUT+="=== FUNCTION URL AUTH ANALYSIS ===
AuthType: ${AUTH_TYPE:-UNKNOWN}
Resource policy exists: ${HAS_RESOURCE_POLICY}
Resource policy grants lambda:InvokeFunctionUrl: ${HAS_INVOKE_URL}
Resource policy grants lambda:InvokeFunction: ${HAS_INVOKE_FUNC}
Resource policy has Principal *: ${HAS_STAR_PRINCIPAL}
Resource policy has Allow effect: ${HAS_ALLOW}
Resource policy has Deny on invoke actions: ${HAS_DENY_INVOKE}
FunctionUrlAuthType condition present: ${HAS_AUTH_TYPE_CONDITION}
FunctionUrlAuthType condition value: ${CONDITION_AUTH_TYPE:-N/A}
SCP may block InvokeFunctionUrl: ${SCP_BLOCKS_INVOKE}
SCP enforces AWS_IAM only (blocks NONE): ${SCP_BLOCKS_NONE}

"
