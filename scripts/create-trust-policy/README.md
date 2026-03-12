# Create Trust Policy

Creates an IAM trust policy by prompting for principals.

## Usage

```bash
./run.sh
```

## Description

Interactive script that prompts for:
- Principal type (user, role, or service)
- Principal value (ARN for user/role, AWS service name)
- IP address for all principal types
- Loops until user presses enter to finish

## Security Features

- Enforces MFA and IP address restrictions for users
- Enforces IP address restrictions for roles and services

## Output

Generates IAM trust policy JSON with specified principals and security conditions.
