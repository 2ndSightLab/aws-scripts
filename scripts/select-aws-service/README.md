# Select AWS Service

This script allows you to select an AWS service from various listing sources.

## What it does

1. Prompts you to select an AWS CLI profile
2. Prompts you to choose a listing source (help, pricing, support, service-quotas, iam, organizations, or resource-explorer)
3. Lists all available AWS services from the selected source
4. Shows the total count of services
5. Prompts you to select a specific service from the list
6. Validates that the selected service exists in the list

## Usage

```bash
./run.sh
```

## Output

The script sets the `SERVICE` variable with your selected AWS service name.
