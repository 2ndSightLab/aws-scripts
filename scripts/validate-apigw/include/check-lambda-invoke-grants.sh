#!/bin/bash
# Check 2: No backend Lambda has any lambda:InvokeFunction grant outside of API Gateway

echo ""
echo "=== Check 2: Lambda InvokeFunction grants restricted to API Gateway ==="

CHECK2_FAIL=0
for FUNC_ARN in "${BACKEND_LAMBDA_ARNS[@]}"; do
    FUNC_NAME="${FUNC_ARN##*:function:}"
    echo "  Checking ${FUNC_NAME}..."

    # Check resource-based policy
    POLICY=$(aws lambda get-policy \
        --function-name "${FUNC_ARN}" \
        --profile "${PROFILE}" \
        --region "${REGION}" \
        --output json 2>&1)
    POLICY_RC=$?

    if [ $POLICY_RC -ne 0 ]; then
        if echo "${POLICY}" | grep -q "ResourceNotFoundException"; then
            echo "    OK: No resource policy (no external invoke grants)"
        else
            echo "    WARNING: Could not retrieve policy: ${POLICY}"
            CHECK2_FAIL=$((CHECK2_FAIL + 1))
        fi
        continue
    fi

    # Parse policy statements - look for lambda:InvokeFunction with non-apigateway principals
    POLICY_DOC=$(echo "${POLICY}" | grep -o '"Policy"[[:space:]]*:[[:space:]]*"[^"]*"' | sed 's/"Policy"[[:space:]]*:[[:space:]]*"//;s/"$//' | sed 's/\\"/"/g;s/\\\\/\\/g')

    # Check each statement for non-apigateway principals with InvokeFunction
    STMT_COUNT=$(echo "${POLICY_DOC}" | grep -o '"Effect"' | wc -l)
    HAS_NON_APIGW=$(echo "${POLICY_DOC}" | grep -i 'InvokeFunction' | grep -v 'apigateway.amazonaws.com' || true)

    if [ -n "${HAS_NON_APIGW}" ]; then
        echo "    FAIL: Found lambda:InvokeFunction grants not restricted to apigateway.amazonaws.com"
        echo "    ${HAS_NON_APIGW}"
        CHECK2_FAIL=$((CHECK2_FAIL + 1))
    else
        echo "    OK: All InvokeFunction grants are for apigateway.amazonaws.com"
    fi

    # Check IAM policies that grant lambda:InvokeFunction on this function
    # Search IAM policies in the account
    echo "    Checking IAM policies for InvokeFunction grants..."
    LOCAL_POLICIES=$(aws iam list-policies \
        --scope Local \
        --profile "${PROFILE}" \
        --region "${REGION}" \
        --output json 2>&1)

    if [ $? -eq 0 ]; then
        POLICY_ARNS=$(echo "${LOCAL_POLICIES}" | grep -o '"Arn"[[:space:]]*:[[:space:]]*"[^"]*"' | sed 's/.*"\(arn[^"]*\)"/\1/')
        for PARN in ${POLICY_ARNS}; do
            VER_ID=$(aws iam get-policy --policy-arn "${PARN}" --profile "${PROFILE}" --region "${REGION}" --output json 2>&1 | grep -o '"DefaultVersionId"[[:space:]]*:[[:space:]]*"[^"]*"' | sed 's/.*"\([^"]*\)"/\1/')
            if [ -z "${VER_ID}" ]; then continue; fi

            PDOC=$(aws iam get-policy-version --policy-arn "${PARN}" --version-id "${VER_ID}" --profile "${PROFILE}" --region "${REGION}" --output json 2>&1)

            if echo "${PDOC}" | grep -qi 'InvokeFunction'; then
                if echo "${PDOC}" | grep -q "${FUNC_NAME}\|${FUNC_ARN}"; then
                    echo "    FAIL: IAM policy ${PARN} grants InvokeFunction on ${FUNC_NAME}"
                    CHECK2_FAIL=$((CHECK2_FAIL + 1))
                fi
            fi
        done
    fi

    # Check execution role doesn't have InvokeFunction on backend lambdas
    FUNC_CONFIG=$(aws lambda get-function-configuration \
        --function-name "${FUNC_ARN}" \
        --profile "${PROFILE}" \
        --region "${REGION}" \
        --output json 2>&1)
    EXEC_ROLE=$(echo "${FUNC_CONFIG}" | grep -o '"Role"[[:space:]]*:[[:space:]]*"[^"]*"' | sed 's/.*"\(arn[^"]*\)"/\1/')

    if [ -n "${EXEC_ROLE}" ]; then
        ROLE_NAME="${EXEC_ROLE##*/}"
        ATTACHED=$(aws iam list-attached-role-policies --role-name "${ROLE_NAME}" --profile "${PROFILE}" --region "${REGION}" --output json 2>&1)
        ATTACHED_ARNS=$(echo "${ATTACHED}" | grep -o '"PolicyArn"[[:space:]]*:[[:space:]]*"[^"]*"' | sed 's/.*"\(arn[^"]*\)"/\1/')

        for AARN in ${ATTACHED_ARNS}; do
            AVER_ID=$(aws iam get-policy --policy-arn "${AARN}" --profile "${PROFILE}" --region "${REGION}" --output json 2>&1 | grep -o '"DefaultVersionId"[[:space:]]*:[[:space:]]*"[^"]*"' | sed 's/.*"\([^"]*\)"/\1/')
            if [ -z "${AVER_ID}" ]; then continue; fi

            APDOC=$(aws iam get-policy-version --policy-arn "${AARN}" --version-id "${AVER_ID}" --profile "${PROFILE}" --region "${REGION}" --output json 2>&1)
            if echo "${APDOC}" | grep -qi 'InvokeFunction'; then
                for CHECK_ARN in "${BACKEND_LAMBDA_ARNS[@]}"; do
                    CHECK_NAME="${CHECK_ARN##*:function:}"
                    if echo "${APDOC}" | grep -q "${CHECK_NAME}\|${CHECK_ARN}\|\*"; then
                        echo "    FAIL: Execution role ${ROLE_NAME} policy ${AARN} grants InvokeFunction on ${CHECK_NAME}"
                        CHECK2_FAIL=$((CHECK2_FAIL + 1))
                    fi
                done
            fi
        done

        INLINE=$(aws iam list-role-policies --role-name "${ROLE_NAME}" --profile "${PROFILE}" --region "${REGION}" --output json 2>&1)
        INLINE_NAMES=$(echo "${INLINE}" | grep -o '"[^"]*"' | tr -d '"' | grep -v PolicyNames | grep -v '\[' | grep -v '\]')
        for INAME in ${INLINE_NAMES}; do
            IPDOC=$(aws iam get-role-policy --role-name "${ROLE_NAME}" --policy-name "${INAME}" --profile "${PROFILE}" --region "${REGION}" --output json 2>&1)
            if echo "${IPDOC}" | grep -qi 'InvokeFunction'; then
                for CHECK_ARN in "${BACKEND_LAMBDA_ARNS[@]}"; do
                    CHECK_NAME="${CHECK_ARN##*:function:}"
                    if echo "${IPDOC}" | grep -q "${CHECK_NAME}\|${CHECK_ARN}\|\*"; then
                        echo "    FAIL: Execution role ${ROLE_NAME} inline policy ${INAME} grants InvokeFunction on ${CHECK_NAME}"
                        CHECK2_FAIL=$((CHECK2_FAIL + 1))
                    fi
                done
            fi
        done
    fi
done

if [ ${CHECK2_FAIL} -eq 0 ]; then
    echo "  PASS: No unauthorized InvokeFunction grants found"
else
    PROBLEMS_FOUND=$((PROBLEMS_FOUND + CHECK2_FAIL))
    PROBLEMS_OUTPUT+="Check 2: ${CHECK2_FAIL} unauthorized InvokeFunction grant(s) found\n"
fi
