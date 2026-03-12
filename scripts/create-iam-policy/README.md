# Create IAM Policy Script

This script creates AWS IAM policies with multiple statements and optionally attaches them to users, roles, or groups.

## Features

- Interactive policy creation with multiple statements
- Service and action selection using external scripts
- Multiple service support per policy
- Policy validation and preview
- Automatic policy updates for existing policies
- Policy attachment to users, roles, or groups

## Usage

```bash
./run.sh
```

## Process

1. **Profile Selection**: Select AWS CLI profile
2. **Policy Name**: Enter policy name
3. **Statement Creation**: For each statement:
   - Enter alphanumeric SID
   - Choose Effect (Allow/Deny)
   - Select services and actions (loops for multiple services)
   - Enter resources (at least one required)
4. **Policy Preview**: Review generated JSON policy
5. **Policy Creation**: Creates new policy or updates existing
6. **Attachment**: Optionally attach to user, role, or group

## Requirements

- AWS CLI configured with appropriate permissions
- `jq` for JSON processing
- Access to `../select-actions/run.sh` script
- Access to `../select-aws-cli-profile/run.sh` script

## Dependencies

- `select-actions` script for service/action selection
- `select-aws-cli-profile` script for profile selection
