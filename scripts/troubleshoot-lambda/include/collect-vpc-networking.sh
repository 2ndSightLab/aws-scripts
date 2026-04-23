# --- VPC networking data collection (if Lambda is in a VPC) ---
if [ -n "${VPC_ID}" ]; then
    # Subnet route tables and routes
    for SUBNET in $(echo "${LAMBDA_CONFIG}" | grep -o '"subnet-[^"]*"' | tr -d '"' | sort -u); do
        RT_ID=$(aws ec2 describe-route-tables \
            --filters "Name=association.subnet-id,Values=${SUBNET}" \
            --query 'RouteTables[0].RouteTableId' \
            --output text \
            --profile "${PROFILE}" \
            --region "${REGION}" 2>&1)
        RT_RC=$?
        # Fall back to main route table if no explicit association
        if [ $RT_RC -ne 0 ] || [ -z "${RT_ID}" ] || [ "${RT_ID}" = "None" ]; then
            RT_ID=$(aws ec2 describe-route-tables \
                --filters "Name=vpc-id,Values=${VPC_ID}" "Name=association.main,Values=true" \
                --query 'RouteTables[0].RouteTableId' \
                --output text \
                --profile "${PROFILE}" \
                --region "${REGION}" 2>&1)
            RT_RC=$?
        fi
        if [ $RT_RC -eq 0 ] && [ -n "${RT_ID}" ] && [ "${RT_ID}" != "None" ]; then
            ROUTES=$(aws ec2 describe-route-tables \
                --route-table-ids "${RT_ID}" \
                --profile "${PROFILE}" \
                --region "${REGION}" 2>&1)
            LOGS_OUTPUT+="=== ROUTE TABLE ${RT_ID} FOR SUBNET ${SUBNET} ===
${ROUTES}

"
        else
            LOGS_OUTPUT+="=== ROUTE TABLE FOR SUBNET ${SUBNET} ===
Could not retrieve route table: ${RT_ID}

"
        fi
    done

    # NACLs on Lambda subnets
    NACLS=$(aws ec2 describe-network-acls \
        --filters "Name=association.subnet-id,Values=${SUBNET_IDS}" \
        --profile "${PROFILE}" \
        --region "${REGION}" 2>&1)
    NACL_RC=$?
    if [ $NACL_RC -eq 0 ]; then
        LOGS_OUTPUT+="=== NETWORK ACLS FOR LAMBDA SUBNETS ===
${NACLS}

"
    else
        LOGS_OUTPUT+="=== NETWORK ACLS ===
Could not retrieve NACLs: ${NACLS}

"
    fi

    # VPC endpoints — full details including subnet associations and policies
    EP_PROFILE="${PROFILE}"
    if [ "${IS_SHARED_VPC}" = "YES" ]; then
        echo ""
        echo "Shared VPC detected (owner: ${SUBNET_OWNER}). VPC endpoints are not visible from account ${ACCOUNT_ID}."
        read -r -p "Switch to VPC owner account profile to query endpoints? (y/n): " USE_VPC_OWNER_PROFILE
        if [ "${USE_VPC_OWNER_PROFILE}" = "y" ]; then
            SAVED_PROFILE="${PROFILE}"
            unset PROFILE
            OUTPUT="json"
            SECRETS_MANAGER_USED="N"
            EXTERNAL_ID_USED="N"
            source "${SCRIPT_DIR}/assume-role.sh"
            EP_PROFILE="${PROFILE}"
            PROFILE="${SAVED_PROFILE}"
            unset SAVED_PROFILE
        fi
    fi
    VPC_ENDPOINTS=$(aws ec2 describe-vpc-endpoints \
        --filters "Name=vpc-id,Values=${VPC_ID}" \
        --profile "${EP_PROFILE}" \
        --region "${REGION}" 2>&1)
    VPC_EP_RC=$?
    if [ $VPC_EP_RC -eq 0 ]; then
        LOGS_OUTPUT+="=== VPC ENDPOINTS IN ${VPC_ID} ===
${VPC_ENDPOINTS}

"
    else
        LOGS_OUTPUT+="=== VPC ENDPOINTS ===
Could not retrieve VPC endpoints: ${VPC_ENDPOINTS}

"
    fi
fi
