# --- VPC Flow Logs (REJECT only, for Lambda ENIs) ---
VPC_ID=$(echo "${LAMBDA_CONFIG}" | grep -o '"VpcId"[[:space:]]*:[[:space:]]*"[^"]*"' | sed 's/.*"\([^"]*\)"/\1/')
if [ -n "${VPC_ID}" ]; then
    echo "Lambda is in VPC ${VPC_ID}. Fetching VPC details..."
    VPC_DETAILS=$(aws ec2 describe-vpcs \
        --vpc-ids "${VPC_ID}" \
        --profile "${PROFILE}" \
        --region "${REGION}" 2>&1)
    LOGS_OUTPUT+="=== VPC CONFIGURATION ${VPC_ID} ===
${VPC_DETAILS}

"
    SUBNET_DETAILS=$(aws ec2 describe-subnets \
        --filters "Name=vpc-id,Values=${VPC_ID}" \
        --profile "${PROFILE}" \
        --region "${REGION}" 2>&1)
    LOGS_OUTPUT+="=== SUBNETS IN ${VPC_ID} ===
${SUBNET_DETAILS}

"
    # Detect shared VPC by comparing subnet OwnerId to Lambda account
    SUBNET_OWNER=$(echo "${SUBNET_DETAILS}" | grep -o '"OwnerId"[[:space:]]*:[[:space:]]*"[^"]*"' | head -1 | sed 's/.*"\([^"]*\)"/\1/')
    IS_SHARED_VPC="NO"
    if [ -n "${SUBNET_OWNER}" ] && [ "${SUBNET_OWNER}" != "${ACCOUNT_ID}" ]; then
        IS_SHARED_VPC="YES"
        LOGS_OUTPUT+="=== SHARED VPC DETECTED ===
VPC owner account: ${SUBNET_OWNER}
Lambda account: ${ACCOUNT_ID}
VPC endpoints owned by ${SUBNET_OWNER} will not be visible from this account.

"
    fi
    echo "Fetching rejected flow logs..."
    SUBNET_IDS=$(echo "${LAMBDA_CONFIG}" | grep -o '"SubnetIds"[[:space:]]*:[[:space:]]*\[[^]]*\]' | grep -o '"subnet-[^"]*"' | tr -d '"' | tr '\n' ',' | sed 's/,$//')
    ENI_IDS=$(aws ec2 describe-network-interfaces \
        --filters "Name=vpc-id,Values=${VPC_ID}" "Name=subnet-id,Values=${SUBNET_IDS}" "Name=requester-id,Values=*lambda*" \
        --query 'NetworkInterfaces[].NetworkInterfaceId' \
        --output text \
        --profile "${PROFILE}" \
        --region "${REGION}" 2>&1)
    ENI_RC=$?

    # Fallback: try description filter if requester-id found nothing
    if [ $ENI_RC -ne 0 ] || [ -z "${ENI_IDS}" ]; then
        ENI_IDS=$(aws ec2 describe-network-interfaces \
            --filters "Name=vpc-id,Values=${VPC_ID}" "Name=description,Values=*Lambda*${FUNCTION_NAME}*" \
            --query 'NetworkInterfaces[].NetworkInterfaceId' \
            --output text \
            --profile "${PROFILE}" \
            --region "${REGION}" 2>&1)
        ENI_RC=$?
    fi

    if [ $ENI_RC -eq 0 ] && [ -n "${ENI_IDS}" ]; then
        LOGS_OUTPUT+="=== LAMBDA ENIs ===
${ENI_IDS}

"
        # Find flow log group for this VPC or Lambda subnets
        FLOW_LOG_GROUP=$(aws ec2 describe-flow-logs \
            --filter "Name=resource-id,Values=${VPC_ID},${SUBNET_IDS}" \
            --query 'FlowLogs[?LogDestinationType==`cloud-watch-logs`].LogGroupName | [0]' \
            --output text \
            --profile "${PROFILE}" \
            --region "${REGION}" 2>&1)
        FL_RC=$?

        if [ $FL_RC -eq 0 ] && [ -n "${FLOW_LOG_GROUP}" ] && [ "${FLOW_LOG_GROUP}" != "None" ]; then
            # Build filter for REJECT traffic on Lambda ENIs
            ENI_FILTER=""
            for ENI in ${ENI_IDS}; do
                if [ -n "${ENI_FILTER}" ]; then
                    ENI_FILTER+=" || "
                fi
                ENI_FILTER+="\$.interfaceId = \"${ENI}\""
            done

            FLOW_LOGS=$(aws logs filter-log-events \
                --log-group-name "${FLOW_LOG_GROUP}" \
                --start-time "${LOOKBACK_MS}" \
                --filter-pattern "{ (${ENI_FILTER}) && \$.action = \"REJECT\" }" \
                --limit 200 \
                --query 'events[].message' \
                --output text \
                --profile "${PROFILE}" \
                --region "${REGION}" 2>&1)
            FLOW_RC=$?

            if [ $FLOW_RC -eq 0 ] && [ -n "${FLOW_LOGS}" ]; then
                LOGS_OUTPUT+="=== VPC FLOW LOGS - REJECTED TRAFFIC (last 1 hour) ===
${FLOW_LOGS}

"
            else
                LOGS_OUTPUT+="=== VPC FLOW LOGS - REJECTED TRAFFIC ===
No rejected traffic found or error: ${FLOW_LOGS}

"
            fi
        else
            LOGS_OUTPUT+="=== VPC FLOW LOGS ===
No CloudWatch flow log group found for VPC ${VPC_ID}. Flow logs may not be enabled or may use S3 destination.

"
            PROBLEMS_OUTPUT+="PROBLEM: No CloudWatch flow log group found for VPC ${VPC_ID}. VPC flow logs may not be enabled or may be configured to send to S3 instead of CloudWatch.
FIX: Enable VPC flow logs to CloudWatch for troubleshooting:
  aws ec2 create-flow-logs --resource-type VPC --resource-ids ${VPC_ID} --traffic-type ALL --log-destination-type cloud-watch-logs --log-group-name /aws/vpc/flowlogs/${VPC_ID} --deliver-logs-permission-arn <flow-log-role-arn> --region ${REGION}

"
            PROBLEMS_FOUND=$((PROBLEMS_FOUND+1))
        fi

    else
        LOGS_OUTPUT+="=== VPC FLOW LOGS ===
Could not find Lambda ENIs: ${ENI_IDS}

"
        PROBLEMS_OUTPUT+="PROBLEM: Could not find Lambda ENIs in VPC ${VPC_ID}. VPC flow log analysis is not possible without identifying the Lambda network interfaces.
FIX: Ensure the assumed role has ec2:DescribeNetworkInterfaces permission and the Lambda function has been invoked recently (ENIs are created on invocation).

"
        PROBLEMS_FOUND=$((PROBLEMS_FOUND+1))
    fi
    # Security groups from Lambda configuration
    SG_IDS=$(echo "${LAMBDA_CONFIG}" | grep -o '"SecurityGroupIds"[[:space:]]*:[[:space:]]*\[[^]]*\]' | grep -o '"sg-[^"]*"' | tr -d '"' | tr '\n' ' ')
    if [ -n "${SG_IDS}" ]; then
        SG_RULES=$(aws ec2 describe-security-groups \
            --group-ids ${SG_IDS} \
            --profile "${PROFILE}" \
            --region "${REGION}" 2>&1)
        LOGS_OUTPUT+="=== LAMBDA SECURITY GROUPS ===
${SG_RULES}

"
    fi
fi
