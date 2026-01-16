# Select Region

Interactive script that allows users to select an AWS region from a numbered list.

## Usage

```bash
./run.sh
```

## What it does

1. Sources AWS CLI profile selection
2. Lists all available AWS regions for the selected profile
3. Prompts user to select a region by number
4. Validates input and sets the REGION variable
5. Displays the selected region

## Dependencies

- `../select-aws-cli-profile/run.sh` - AWS profile selection
- `../../functions/list_regions.sh` - Region listing function
