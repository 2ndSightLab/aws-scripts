#!/bin/bash -e

cat <<'END_TEXT'

***************************
IAM Roles 
***************************

You may want a record of the IAM role names in this account
in case they appear in any logs or you need to replicate
them again later. Here are a list of the IAM oroles in this account:

END_TEXT

aws iam list-roles --profile $archive_from --region $region \
  --query 'Roles[?starts_with(Path, `/`) && !starts_with(Path, `/aws-service-role/`) && !starts_with(Path, `/aws-reserved/sso/`)].RoleName' \
  --output text \
| xargs -n 1

echo ""

read -p "Copy the names of the roles into a parameter or secret if needed. \
  Enter to continue. Ctrl-C to exit" ok
