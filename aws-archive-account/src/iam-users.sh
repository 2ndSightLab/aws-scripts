#!/bin/bash -e

cat <<'END_TEXT'

***************************
IAM Users 
***************************

You may want a record of the IAM user names in this account
in case they appear in any logs or you need to replicate
them again later. Here are a list of the IAM users in this account:

END_TEXT

aws iam list-users --profile $archive_from --region $region --query "Users[].UserName" --output text \
  | xargs -n 1

read -p "Copy the names of the roles into a parameter or secret if needed. \
  Enter to continue. Ctrl-C to exit" ok
