# Create KMS Key Policy for Logs in OU

This script creates a KMS key policy that allows CloudWatch Logs encryption for accounts within a specific Organizational Unit (OU).

## What it does

The `run.sh` script:

1. **Prompts for AWS profiles** - Selects separate profiles for Organizations and KMS operations
2. **Discovers organization structure** - Automatically finds the organization root ID
3. **Collects permissions configuration**:
   - Role/user ARNs that can read/decrypt logs
   - Organizational Unit ID that can write/encrypt logs
   - IP addresses for administrative access
   - EC2 role ARN for key administration
4. **Selects target KMS key** - Uses existing key selection utility
5. **Creates and applies policy** - Generates a KMS key policy with four statements:
   - Root account permissions
   - CloudWatch Logs service permissions
   - OU-based encryption permissions
   - Specific ARN-based decryption permissions

## Usage

```bash
./run.sh
```

The script will interactively prompt for all required configuration values.

## Requirements

- AWS CLI configured with appropriate profiles
- Organizations read permissions
- KMS key management permissions
- Valid IAM role/user ARNs for log access
- Organizational Unit ID for log writing accounts
