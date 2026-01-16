**Create User Secrets**

__Summmary:__

This repository ccontains a script to create AWS Secrets Mangager secrets. One secret is used to configure AWS CLI Profiles. The other is used to store a user name and GitHub personal accesss token to execute GitHub commands. To simplify deployment this script presumes the user is executing it in the region
where the secret should be created and the user has permission to use the KMS key used to encrypt the secrets.

__Context__

* Must follow all repository standards in https://github.com/2ndSightLab/aws-scripts/blob/main/README.md
* Must follow all script standards in https://github.com/2ndSightLab/aws-scripts/blob/main/scripts/README.md
  
__Steps to create the script__

1. Create a bash script to run on Amazon Linux and add a shebang at that top named run.sh

2. Add the following variables at the top and set to empty string. ENVIRONMENT, USERNAME, USER_ACCOUNT_NUMBER, ACCESS_KEY_ID, SECRET_KEY, GITHUB_USER_NAME, GITHUB_PAT)

3. Ask the user to enter each of the following: ENVIRONMENT, USER_ACCOUNT_NUMBER, USER_ACCOUNT_NAME, ACCESS_KEY_ID, SECRET_KEY with each prompt in a loop that asks the user again until the user enters a value.

4. Within each loop, validate that the entry except ENVIRONMENT is valid based on AWS documentation. Validate that ENVIRONMENT is set, not an empty string.

5. Formaulte the secret name for the AWS credentials in this format <$ENVIRONMENT>-<$USERNAME>-<awscli> and convert to all lower case.

6. Ask the user for the KMS encryption key arn to use to encrypt the secret in a while loop untl the user enters an ARN. Validate the format of the ARN.

7. Ask the user to enter each of the following: USERNAME, USER_ACCOUNT_NUMBER, USER_ACCOUNT_NAME, ACCESS_KEY_ID, SECRET_KEY with each prompt in a loop that asks the user again until the user enters a value.

8. Create the secret encrypted with the KMS key in this format:

{"aws_access_key_id":"$ACCESS_KEY_ID","aws_secret_key":"$SECRET_KEY","user_account_id":"$USER_ACCOUNT_NUMBER","mfa_serial":"arn:aws:iam::$USER_ACCOUNT_NUMBER:mfa/$USERNAME"}

9. Formaulte the secret name for the GitHub credentials in this format <$USERNAME>-<github>

10. Ask the user to enter each of the following: GITHUB_USER_NAME, GITHUB_PAT with each prompt in a loop that asks the user again until the user enters a value.

11. Within each loop, validate that the entry is valid based on GitHub documentation.

12. Create the secret encrypted with the KMS key in this format:

{"gh_username":"$GITHUB_USER_NAME","gh_pat":"$GITHUB_PAT"}

13. Echo to the screen that the script is complete.

[ TODO: Add a policy to the secrets ]
