# AWS CLI Source Profile Script

## Purpose
Create a bash script that sets up AWS CLI profiles by sourcing credentials from existing profiles.

## Requirements
- Script name: `run.sh`
- Based on: https://github.com/2ndSightLab/aws-cli-profile/blob/main/create-aws-cli-profile-simple.sh
- Must follow all repository standards from main README.md

## Implementation
- Prompt user for profile name
- Prompt user for AWS access key ID
- Prompt user for AWS secret access key
- Prompt user for AWS region
- Prompt user for output format
- Configure AWS CLI profile using aws configure set commands
- Test profile using aws sts get-caller-identity

## Variables
- PROFILE - AWS CLI profile name to create
- AWS_ACCESS_KEY_ID - AWS access key ID
- AWS_SECRET_ACCESS_KEY - AWS secret access key
- REGION - AWS region (e.g. us-east-1)
- OUTPUT - output format (e.g. json or text)

## Error Handling
- Check if source profile exists and is valid
- Verify AWS CLI is installed
- Confirm new profile creation was successful
