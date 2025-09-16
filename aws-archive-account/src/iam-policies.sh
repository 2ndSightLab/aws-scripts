#!/bin/bash -e

cat <<'END_TEXT'

***************************
IAM Roles 
***************************

You can transfer some or all of the policies in this account
to the new account but note that the principals have to exist
and if deleted, will be turned into an unusable logical ID.
Instead, if you plan to use the policies in the future, 
recreate them in the new archive account using users or roles
in the archive account if needed, or store the policies
in an SSM parameter for future reference.

END_TEXT

aws iam list-policies --profile $archive_from --region $region \
  --scope Local \
  --query "Policies[].PolicyName" \
  --output text \
  | xargs -n 1

read -p "Copy or recreate the above policies as needed. Ctrl-C to exit" ok
