# Deploy EC2 AMI Script

__Summary__
Create a bash script that deploys an EC2 instance from an AMI with comprehensive selection options.

__Context__
* Script name: run.sh
* Must follow all repository standards in https://github.com/2ndSightLab/aws-scripts/blob/main/README.md
* Must follow all script standards in https://github.com/2ndSightLab/aws-scripts/blob/main/scripts/README.md

## Implementation Flow

### 1. Profile Setup
- Ask user to select a region
- List CLI profiles and ask user which profile to use for creating the AMI
- Ask user for profile to use for listing KMS keys (if in separate account)

### 2. AMI Selection
- Ask user: private AMI or AWS AMI
- List available operating systems for user selection
- Ask user which operating system
- List available architectures for user selection  
- Ask user which architecture
- Ask if user wants to see AMI list
- If yes: display unique list showing AMI names filtered in two steps: 1) select value before first slash, 2) select part before first number (or second number if name starts with amzn2), 3) remove trailing dashes
- Ask user to select AMI name prefix
- Display list of AMI IDs, names, and descriptions from newest to oldest that match the selected AMI name prefix
- Prompt for AMI ID

### 3. Instance Configuration
- Ask if user wants to see compatible instance types
- If yes: display instance types compatible with the selected AMI showing vCPUs, memory, network performance, and hourly pricing ordered by network then memory then vCPUs smallest to largest
- Prompt for instance type
- List file names including directory name from user_data_scripts directory
- Use while loop to prompt user for script file names for USER_DATA until user doesn't add anymore script file names
- Create temp file in /tmp directory for userdata and copy selected user data scripts
- Prompt user for placeholder values {{prompt:...}} and replace those prompts in the file with user specified values

### 4. Security & Network Setup
- List available KMS keys (ARN, alias, description) using KMS_PROFILE
- Prompt for key pair ARN
- List available EC2 key pairs and give user option to create new EC2 key pair
- If creating new key pair: ask user to enter KMS key ARN to encrypt the key, create the key and save to secret named ec2-key-pair-[key pair name]
- If creating new key pair: prompt for EC2 key pair name
- List available VPCs (VPC ID and name) and ask user selection
- List available security groups (names, IDs, description)
- Prompt for security group ID
- List subnets (IDs, AZ, name)
- Prompt for subnet ID

### 5. Launch & Display
- Launch EC2 instance
- Display instance details
- Clean up temp user data file

## Variables
- REGION - AWS region to use for all commands
- PROFILE - AWS CLI profile for creating AMI
- KMS_PROFILE - AWS CLI profile for listing KMS keys
- AMI_TYPE - Private AMI or AWS AMI selection
- OS_SELECTION - Selected operating system
- ARCHITECTURE - Selected architecture
- AMI_NAME_SELECTION - Selected AMI name without version
- AMI_ID - AMI ID to launch
- INSTANCE_TYPE - EC2 instance type
- USER_DATA - Script file names for EC2 user data
- USER_DATA_FILE - Path to the temp user data file created in /tmp
- KEY_NAME - EC2 key pair name
- KEY_ARN - EC2 key pair ARN
- KMS_KEY_ARN - KMS key ARN for encrypting new key pairs
- VPC_ID - Selected VPC ID
- SECURITY_GROUP_ID - Security group ID
- SUBNET_ID - Subnet ID

## Notes
- Use --region $REGION and --profile $PROFILE in all AWS CLI commands except where specified otherwise
- Use --profile $KMS_PROFILE for KMS operations and Secrets Manager operations

## Error Handling
- Validate all required inputs are provided
- Check AMI exists and is available
- Verify key pair exists
- Confirm security group and subnet exist
- Validate user data script files exist
- Check KMS key permissions
- Verify secret creation permissions
- Validate region is valid
- Check if temp directory is writable
- Verify user has permissions to launch EC2 instances
