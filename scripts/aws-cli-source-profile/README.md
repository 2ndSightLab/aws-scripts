# AWS CLI Source Profile Script

__Summary__

Create a profile configured with AWS developer credentials. Best practice is to ONLY give those
credentials permission to assume a role with MFA and preferrably also restricted to specific IP
address(es). Then create a separate AWS CLI profile to assume a role with MFA using this script:
https://github.com/2ndSightLab/aws-scripts/tree/main/scripts/aws-cli-role-profile

__Context__

* Must follow all repository standards in https://github.com/2ndSightLab/aws-scripts/blob/main/README.md
* Must follow all script standards in https://github.com/2ndSightLab/aws-scripts/blob/main/scripts/README.md

__Implementation__
- Prompt user for profile name
- Prompt user for AWS access key ID
- Prompt user for AWS secret access key
- Prompt user for AWS region
- Prompt user for output format
- Configure AWS CLI profile using aws configure set commands
- Test profile using aws sts get-caller-identity

__Variables__
- PROFILE - AWS CLI profile name to create
- AWS_ACCESS_KEY_ID - AWS access key ID
- AWS_SECRET_ACCESS_KEY - AWS secret access key
- REGION - AWS region (e.g. us-east-1)
- OUTPUT - output format (e.g. json or text)

__Error Handling__
- Check if source profile exists and is valid
- Verify AWS CLI is installed
- Confirm new profile creation was successful
