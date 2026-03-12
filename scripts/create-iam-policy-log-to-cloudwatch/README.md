# IAM Policy for CloudWatch Logging

This script attaches a CloudWatch logging policy to an existing IAM role with IP and KMS encryption restrictions.

## What it does

The `run.sh` script:

1. **Prompts for AWS profile selection** from configured profiles
2. **Collects required parameters** with validation:
   - IAM role name (existing role)
   - CloudWatch log group name
   - Allowed IP address (CIDR format)
   - KMS key ARN for encryption
   - AWS region
   - AWS account ID
   - Policy name

3. **Creates and attaches policy**:
   - Generates a role policy with CloudWatch logging permissions
   - Applies IP and KMS restrictions
   - Attaches the policy to the specified existing IAM role

## Security Features

- **IP restriction**: Only allows access from specified IP address
- **KMS encryption**: Requires specific KMS key for log encryption
- **Least privilege**: Only grants permissions for the specified log group

## Usage

```bash
./run.sh
```

Follow the interactive prompts to configure the policy.

## Requirements

- AWS CLI configured with appropriate profiles
- Existing IAM role to attach the policy to
- Permissions to modify IAM role policies
- Valid KMS key ARN for log encryption
