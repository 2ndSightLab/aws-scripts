# Select Actions Script

This script allows you to select AWS service actions for use in IAM policies.

## Usage

```bash
./run.sh
```

Or set variables before calling:

```bash
SERVICE="s3" PROFILE="default" ./run.sh
```

## What it does

1. Prompts for AWS service name (if SERVICE not set)
2. Prompts for AWS CLI profile (if PROFILE not set)  
3. Lists all available actions for the specified service
4. Allows interactive selection of multiple actions
5. Returns selected actions in comma-separated ACTIONS variable

## Interactive Selection

- Enter action names one at a time
- Type 'list' to see available actions again
- Press Enter (empty input) to finish selection
- Type 'done' to finish selection

## Output

The script sets the ACTIONS variable containing comma-separated action names for use by other scripts.
