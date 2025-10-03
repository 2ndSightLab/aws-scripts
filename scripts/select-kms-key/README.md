# Select KMS Key

This script allows you to select a customer-managed KMS key from your AWS account.

## What it does

1. Prompts you to select an AWS CLI profile (if KMS_PROFILE is not already set)
2. Lists all customer-managed KMS keys in the configured region
3. Displays keys in a formatted table showing ARN and alias
4. Prompts you to enter a KMS key ARN for selection

## Usage

```bash
./run.sh
```

## Output

The script displays a table of available KMS keys:
- **ARN**: The full Amazon Resource Name of the KMS key
- **Alias**: The friendly name/alias of the key (or "N/A" if no alias exists)

If no customer-managed keys are found, it displays an appropriate message.

## Requirements

- AWS CLI configured with appropriate profiles
- KMS permissions: `kms:ListKeys`, `kms:ListAliases`, `kms:DescribeKey`
- Valid AWS credentials for the selected profile

## Variables Set

- `KMS_KEY_ID`: The selected KMS key ARN
- `KMS_PROFILE`: The AWS CLI profile used for KMS operations
