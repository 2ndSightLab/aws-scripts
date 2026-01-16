# AWS CLI Role Profile Script

__Summary__
Create a bash script that sets up AWS CLI profiles for role assumption using an existing profile as the source profile. Use the script in this directory to configure the source profile: 
https://github.com/2ndSightLab/aws-scripts/tree/main/scripts/aws-cli-source-profile

__Context__

* Must follow all repository standards in https://github.com/2ndSightLab/aws-scripts/blob/main/README.md
* Must follow all script standards in https://github.com/2ndSightLab/aws-scripts/blob/main/scripts/README.md
  
__Implementation__

- Check if $PROFILE variable is set, if not prompt user to enter it
- If user was prompted for profile, validate it exists using `aws sts get-caller-identity`
- Prompt for role profile name
- Prompt for role ARN to assume
- Prompt for MFA serial ARN
- Prompt for external ID (optional)
- Prompt for region
- Prompt for output format
- Configure role profile with role_arn, mfa_serial, external_id (if provided), region, output, and source_profile
- Test role assumption with new profile

__Variables__
- PROFILE - existing AWS CLI profile name (source_profile)
- ROLE_PROFILE - name for new role assumption profile
- ROLE_ARN - ARN of the role to assume
- MFA_SERIAL - MFA device serial ARN
- EXTERNAL_ID - external ID for role assumption (optional)
- REGION - AWS region (e.g. us-east-1)
- OUTPUT - output format (e.g. json or text)

__Error Handling__
- Check if PROFILE variable is set
- Verify source profile exists and is valid (only if user was prompted)
- Validate role ARN format
- Test role assumption works with new profile
