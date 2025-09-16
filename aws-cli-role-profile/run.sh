#!/bin/bash
set -e

echo "Available CLI profiles:"
aws configure list-profiles

echo "Do you want to set the organizational profile? (y/n):"
read SET_ORG_PROFILE
if [ "$SET_ORG_PROFILE" = "y" ]; then
    while [ -z "$ORG_PROFILE" ]; do
        echo "Enter organizational profile name:"
        read ORG_PROFILE
        if [ -z "$ORG_PROFILE" ]; then
            echo "ERROR: Organizational profile name cannot be empty. Please enter a valid profile name."
        fi
    done
fi

PROMPTED_FOR_PROFILE=false

if [ -z "$PROFILE" ]; then
    while [ -z "$PROFILE" ]; do
        echo "Enter source profile name"
        read PROFILE
        if [ -z "$PROFILE" ]; then
            echo "ERROR: Profile name cannot be empty. Please enter a valid profile name."
        fi
    done
    PROMPTED_FOR_PROFILE=true
fi

if [ "$PROMPTED_FOR_PROFILE" = true ]; then
    if ! aws sts get-caller-identity --profile "$PROFILE" >/dev/null 2>&1; then
        echo "ERROR: Profile '$PROFILE' is not valid or does not exist. Please check your AWS CLI configuration."
        exit 1
    fi
fi

if [ -n "$ORG_PROFILE" ]; then
    echo "Organization accounts:"
    aws organizations list-accounts --profile "$ORG_PROFILE" --query 'Accounts[*].[Id,Name]' --output table
fi

while [ -z "$ROLE_PROFILE" ]; do
    echo "Enter role profile"
    read ROLE_PROFILE
    if [ -z "$ROLE_PROFILE" ]; then
        echo "ERROR: Role profile name cannot be empty. Please enter a valid role profile name."
    fi
done

while [ -z "$ROLE_ARN" ]; do
    echo "Enter role arn"
    read ROLE_ARN
    if [ -z "$ROLE_ARN" ]; then
        echo "ERROR: Role ARN cannot be empty. Please enter a valid role ARN."
    fi
done

while [ -z "$MFA_SERIAL" ]; do
    echo "Enter mfa arn"
    read MFA_SERIAL
    if [ -z "$MFA_SERIAL" ]; then
        echo "ERROR: MFA ARN cannot be empty. Please enter a valid MFA device ARN."
    fi
done

echo "Enter external id"
read EXTERNAL_ID

while [ -z "$REGION" ]; do
    echo "Enter region (e.g. us-east-1)"
    read REGION
    if [ -z "$REGION" ]; then
        echo "ERROR: Region cannot be empty. Please enter a valid AWS region."
    fi
done

while [ -z "$OUTPUT" ]; do
    echo "Enter output format (e.g. json or text)"
    read OUTPUT
    if [ -z "$OUTPUT" ]; then
        echo "ERROR: Output format cannot be empty. Please enter json or text."
    fi
done

aws configure set role_arn "$ROLE_ARN" --profile "$ROLE_PROFILE"
aws configure set mfa_serial "$MFA_SERIAL" --profile "$ROLE_PROFILE"
if [ "$EXTERNAL_ID" != "" ]; then 
  aws configure set external_id "$EXTERNAL_ID" --profile "$ROLE_PROFILE"
fi
aws configure set region "$REGION" --profile "$ROLE_PROFILE"
aws configure set output "$OUTPUT" --profile "$ROLE_PROFILE"
aws configure set source_profile "$PROFILE" --profile "$ROLE_PROFILE"

aws sts get-caller-identity --profile "$ROLE_PROFILE"
