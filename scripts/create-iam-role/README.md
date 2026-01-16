# Create IAM Role Script

## Overview
This script creates or updates AWS IAM roles with trust policies and optional policy attachments.

## What it does
- Prompts for AWS profile selection
- Creates new IAM roles or updates existing ones
- Configures trust policies for EC2 instances, users, or other roles
- Restricts access by IP address using CIDR notation
- Creates instance profiles for EC2 service roles
- Optionally attaches policies to the role

## Usage
```bash
./run.sh
```

## Interactive Prompts
1. **AWS Profile**: Select from available AWS CLI profiles
2. **Role Name**: Enter the IAM role name
3. **Role Type**: Choose who will use the role:
   - EC2 instances (creates instance profile)
   - Users (requires user ARN)
   - Other roles (requires role ARN)
4. **IP Address**: Enter allowed IP in CIDR format (e.g., 192.168.1.0/24)
5. **Policy Attachment**: Optionally attach existing policy or create new one

## Features
- Validates IP addresses in CIDR format
- Checks if role already exists before creation
- Creates instance profiles automatically for EC2 roles
- Provides clear warnings about AWS console trust policy refresh behavior
- Uses consistent AWS CLI parameters (--no-cli-pager --color off)

## Dependencies
- AWS CLI configured with profiles
- `create_iam_role_trust_policy.sh` function
- `select-aws-cli-profile` script
