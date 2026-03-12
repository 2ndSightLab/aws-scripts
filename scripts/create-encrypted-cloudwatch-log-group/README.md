# Create Encrypted CloudWatch Log Group

This script creates or updates an encrypted CloudWatch log group with configurable retention and log class settings.

## Features

- Creates new encrypted CloudWatch log groups
- Updates existing log groups (retention policy only)
- KMS encryption support
- Configurable log class (STANDARD or INFREQUENT_ACCESS)
- Configurable retention period
- Multi-profile AWS CLI support

## Usage

```bash
./run.sh
```

## Interactive Prompts

1. **KMS Profile Selection**: Choose AWS CLI profile for KMS operations
2. **CloudWatch Profile Selection**: Choose AWS CLI profile for CloudWatch operations
3. **KMS Key Selection**: Select encryption key from available KMS keys
4. **Log Group Name**: Enter the CloudWatch log group name
5. **Retention Days**: Enter log retention period in days
6. **Log Class**: Choose between STANDARD or INFREQUENT_ACCESS

## Log Classes

- **STANDARD**: Higher cost, faster queries, real-time processing
- **INFREQUENT_ACCESS**: Lower cost, slower queries, 12-hour delay for processing

## Dependencies

- AWS CLI configured with appropriate profiles
- Access to KMS keys for encryption
- CloudWatch Logs permissions

## Output

Returns the ARN of the created or updated log group.

## Notes

- KMS key and log class cannot be changed after log group creation
- Retention policy can be updated on existing log groups
- Script automatically detects if log group exists and handles accordingly
