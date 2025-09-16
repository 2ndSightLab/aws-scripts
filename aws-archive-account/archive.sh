#!/bin/bash
# copy resources from an account to an archive account
################

#these variables contain the AWS CLI profiles used in the to and from AWS account
archive_to=""
archive_from=""
clear
echo ""
echo "About this script"
echo "***************************"
echo ""
echo "Blog posts:"
echo ""
echo "https://medium.com/cloud-security/archiving-an-aws-account-e3b47bf1bdd3"
echo ""
echo "This script presumes you are running it with:"
echo "* A user in the archive account (to_account) that has:"
echo "* Permission to assume an archive role in the to_account"
echo "* Permission to assume an archive role in the from_account"
echo "* The roles in both accounts have required permissions."
echo ""
read -p "Have you created the user, roles and policies? Ctrl-C to exit. Enter to continue." ok
echo ""
echo "You can do the following with this script:"
echo ""
echo "1 Archive: archive or copy resources from one AWS account to another"
echo "2 Launch an instance from an AMI to test it with a given profile before you deregister the source AMI"
echo "3 Apply a lifecycle rule to a bucket"
echo ""
read -p "Enter the number for the action you want to run: " action
echo ""
[[ " $list " =~ " $value " ]] && echo "Action: $action" || (echo "Action $action is invalid"; exit 1)
if [ "$action" == "2" ]; then
source src/test-ami.sh
exit 0
fi 

if [ "$action" == "3" ]; then 
source src/s3-lifecycle.sh
exit 0
fi

echo ""
echo "Configure to_account and from_account CLI profiles"
echo "***************************"
echo "Enter the name of or configure AWS CLI profiles for the from account and to account."
echo ""
echo "Profiles on this system"
echo "***************************"
aws configure list-profiles
echo ""
echo "Are the from and to account profiles in the list? If not, ctrl-c to exit."
echo "You can use these scripts to configure your profiles:"
echo "https://github.com/2ndSightLab/aws-cli-profile"
echo ""
read -p "Enter the profile for the from account: " archive_from
echo "Validate credentials for $archive_from:"
aws sts get-caller-identity --profile $archive_from
echo ""
read -p "Enter the profile from the to account: " archive_to
echo "Validate credentials for $archive_to:"
aws sts get-caller-identity --profile $archive_to
echo ""
read -p "Enter the profile used to list the KMS keys used to encrypt new resources: " kms_profile
echo "Validate credentials for $kms_profile:"
aws sts get-caller-identity --profile $kms_profile 
echo ""
read -p "Enter region: " region

source src/s3-buckets.sh
source src/amis.sh
source src/secrets.sh
source src/parameters.sh

echo "*************************"
echo "Resources to manually review"
echo "*************************"
source src/eips.sh
source src/dns.sh
source src/iam-users.sh
source src/iam-roles.sh
source src/iam-policies.sh
echo ""
echo "Archive complete."
