#!/bin/bash
set -e

while [ -z "$PROFILE" ]; do
    echo "Enter profile name"
    read PROFILE
    if [ -z "$PROFILE" ]; then
        echo "ERROR: Profile name cannot be empty. Please enter a valid profile name."
    fi
done

while [ -z "$AWS_ACCESS_KEY_ID" ]; do
    echo "Enter Key ID:"
    read AWS_ACCESS_KEY_ID
    if [ -z "$AWS_ACCESS_KEY_ID" ]; then
        echo "ERROR: Access Key ID cannot be empty. Please enter a valid AWS Access Key ID."
    fi
done

while [ -z "$AWS_SECRET_ACCESS_KEY" ]; do
    echo "Enter secret access key:"
    read AWS_SECRET_ACCESS_KEY
    if [ -z "$AWS_SECRET_ACCESS_KEY" ]; then
        echo "ERROR: Secret Access Key cannot be empty. Please enter a valid AWS Secret Access Key."
    fi
done

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

aws configure set aws_access_key_id "$AWS_ACCESS_KEY_ID" --profile "$PROFILE"
aws configure set aws_secret_access_key "$AWS_SECRET_ACCESS_KEY" --profile "$PROFILE"
aws configure set region "$REGION" --profile "$PROFILE"
aws configure set output "$OUTPUT" --profile "$PROFILE"

#test your profile
aws sts get-caller-identity --profile "$PROFILE"
