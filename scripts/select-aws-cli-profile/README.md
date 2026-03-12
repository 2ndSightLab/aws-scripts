# AWS Profile Selector

Interactive script to select and validate AWS CLI profiles.

## What it does

1. Lists all configured AWS profiles with numbers
2. Prompts user to select a profile by number
3. Validates the selected profile has:
   - Valid region format (xx-xxxx-x, e.g., us-east-1)
   - Valid output format (json, text, table, yaml, yaml-stream)
4. Runs `aws sts get-caller-identity` to verify credentials

## Usage

```bash
./run.sh
```

## Requirements

- AWS CLI installed and configured
- At least one AWS profile configured
- Valid credentials for the selected profile

## Error handling

- Exits if no profiles found
- Loops until valid profile number selected
- Shows fix commands for invalid region/output configurations
- Exits if STS call fails
