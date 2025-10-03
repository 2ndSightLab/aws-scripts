#!/bin/bash

create_iam_role_trust_policy() {
    local PRINCIPAL_TYPE="$1"
    local PRINCIPAL="$2"
    local IP_ADDRESS="$3"
    
    if [[ -z "$PRINCIPAL_TYPE" || -z "$PRINCIPAL" ]]; then
        echo "Error: PRINCIPAL_TYPE and PRINCIPAL are required" >&2
        return 1
    fi
    
    if [[ "$PRINCIPAL_TYPE" != "service" && "$PRINCIPAL_TYPE" != "user" && "$PRINCIPAL_TYPE" != "role" ]]; then
        echo "Error: PRINCIPAL_TYPE must be 'service', 'user', or 'role'" >&2
        return 1
    fi
    
    if [[ "$PRINCIPAL_TYPE" == "role" || "$PRINCIPAL_TYPE" == "service" ]] && [[ -z "$IP_ADDRESS" ]]; then
        echo "Error: IP_ADDRESS is required for role and service principal types" >&2
        return 1
    fi
    
    if [[ "$PRINCIPAL_TYPE" == "service" ]]; then
        if [[ ! "$PRINCIPAL" =~ ^[a-z0-9-]+$ ]]; then
            echo "Error: Service name must contain only lowercase letters, numbers, and hyphens" >&2
            return 1
        fi
        PRINCIPAL_VALUE="$PRINCIPAL.amazonaws.com"
        PRINCIPAL_KEY="Service"
        CONDITION='"IpAddress": { "aws:SourceIp": "'$IP_ADDRESS'" }'
    elif [[ "$PRINCIPAL_TYPE" == "user" ]]; then
        if [[ ! "$PRINCIPAL" =~ ^arn:aws:iam::[0-9]{12}:user/.+ ]]; then
            echo "Error: User principal must be a valid user ARN" >&2
            return 1
        fi
        PRINCIPAL_VALUE="$PRINCIPAL"
        PRINCIPAL_KEY="AWS"
        if [[ -n "$IP_ADDRESS" ]]; then
            CONDITION='"Bool": { "aws:MultiFactorAuthPresent": "true" }, "IpAddress": { "aws:SourceIp": "'$IP_ADDRESS'" }'
        else
            CONDITION='"Bool": { "aws:MultiFactorAuthPresent": "true" }'
        fi
    else
        if [[ ! "$PRINCIPAL" =~ ^arn:aws:iam::[0-9]{12}:role/.+ ]]; then
            echo "Error: Role principal must be a valid role ARN" >&2
            return 1
        fi
        PRINCIPAL_VALUE="$PRINCIPAL"
        PRINCIPAL_KEY="AWS"
        CONDITION='"IpAddress": { "aws:SourceIp": "'$IP_ADDRESS'" }'
    fi
    
    cat << EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "$PRINCIPAL_KEY": "$PRINCIPAL_VALUE"
      },
      "Action": "sts:AssumeRole",
      "Condition": {
        $CONDITION
      }
    }
  ]
}
EOF
}
