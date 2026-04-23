#!/bin/bash
# Check 6: lambda:UpdateFunctionConfiguration and lambda:PutFunctionPolicy are restricted

echo ""
echo "=== Check 6: Dangerous Lambda permissions are restricted ==="

DANGEROUS_ACTIONS=("UpdateFunctionConfiguration" "PutFunctionPolicy")
CHECK6_FAIL=0

# Check IAM policies in the account for these dangerous actions on backend lambdas
LOCAL_POLICIES=$(aws iam list-policies \
    --scope Local \
    --profile "${PROFILE}" \
    --region "${REGION}" \
    --output json 2>&1)

if [ $? -ne 0 ]; then
    echo "  WARNING: Could not list IAM policies: ${LOCAL_POLICIES}"
    PROBLEMS_FOUND=$((PROBLEMS_FOUND + 1))
    PROBLEMS_OUTPUT+="Check 6: Could not list IAM policies\n"
    return
fi

POLICY_ARNS=$(echo "${LOCAL_POLICIES}" | grep -o '"Arn"[[:space:]]*:[[:space:]]*"[^"]*"' | sed 's/.*"\(arn[^"]*\)"/\1/')

for PARN in ${POLICY_ARNS}; do
    VER_ID=$(aws iam get-policy --policy-arn "${PARN}" --profile "${PROFILE}" --region "${REGION}" --output json 2>&1 | grep -o '"DefaultVersionId"[[:space:]]*:[[:space:]]*"[^"]*"' | sed 's/.*"\([^"]*\)"/\1/')
    if [ -z "${VER_ID}" ]; then continue; fi

    PDOC=$(aws iam get-policy-version --policy-arn "${PARN}" --version-id "${VER_ID}" --profile "${PROFILE}" --region "${REGION}" --output json 2>&1)

    for ACTION in "${DANGEROUS_ACTIONS[@]}"; do
        if echo "${PDOC}" | grep -qi "${ACTION}"; then
            for FUNC_ARN in "${BACKEND_LAMBDA_ARNS[@]}"; do
                FUNC_NAME="${FUNC_ARN##*:function:}"
                if echo "${PDOC}" | grep -q "${FUNC_NAME}\|${FUNC_ARN}\|\*"; then
                    POLICY_NAME=$(echo "${LOCAL_POLICIES}" | grep -B2 "${PARN}" | grep -o '"PolicyName"[[:space:]]*:[[:space:]]*"[^"]*"' | sed 's/.*"\([^"]*\)"/\1/')
                    echo "  FAIL: Policy '${POLICY_NAME}' (${PARN}) grants lambda:${ACTION} on ${FUNC_NAME}"
                    CHECK6_FAIL=$((CHECK6_FAIL + 1))
                fi
            done
        fi
    done
done

# Also check roles that might have inline policies with these permissions
echo "  Checking IAM roles for dangerous inline policies..."
ROLES=$(aws iam list-roles --profile "${PROFILE}" --region "${REGION}" --output json 2>&1)
ROLE_NAMES=$(echo "${ROLES}" | grep -o '"RoleName"[[:space:]]*:[[:space:]]*"[^"]*"' | sed 's/.*"\([^"]*\)"/\1/')

for RNAME in ${ROLE_NAMES}; do
    INLINE=$(aws iam list-role-policies --role-name "${RNAME}" --profile "${PROFILE}" --region "${REGION}" --output json 2>&1)
    INLINE_NAMES=$(echo "${INLINE}" | grep -o '"[^"]*"' | tr -d '"' | grep -v PolicyNames | grep -v '\[' | grep -v '\]')

    for INAME in ${INLINE_NAMES}; do
        IPDOC=$(aws iam get-role-policy --role-name "${RNAME}" --policy-name "${INAME}" --profile "${PROFILE}" --region "${REGION}" --output json 2>&1)
        for ACTION in "${DANGEROUS_ACTIONS[@]}"; do
            if echo "${IPDOC}" | grep -qi "${ACTION}"; then
                for FUNC_ARN in "${BACKEND_LAMBDA_ARNS[@]}"; do
                    FUNC_NAME="${FUNC_ARN##*:function:}"
                    if echo "${IPDOC}" | grep -q "${FUNC_NAME}\|${FUNC_ARN}\|\*"; then
                        echo "  FAIL: Role '${RNAME}' inline policy '${INAME}' grants lambda:${ACTION} on ${FUNC_NAME}"
                        CHECK6_FAIL=$((CHECK6_FAIL + 1))
                    fi
                done
            fi
        done
    done
done

if [ ${CHECK6_FAIL} -eq 0 ]; then
    echo "  PASS: No unrestricted UpdateFunctionConfiguration or PutFunctionPolicy grants found"
else
    PROBLEMS_FOUND=$((PROBLEMS_FOUND + CHECK6_FAIL))
    PROBLEMS_OUTPUT+="Check 6: ${CHECK6_FAIL} unrestricted dangerous permission grant(s) found\n"
fi
