#!/bin/bash -e

archive_secret(){
 local from_secret="$1"
 local to_secret="$2"
 local archive_from="$3"
 local archive_to="$4"
 local region="$5"
 local kms_key_id="$6"

 local SECRET_VALUE=""

 SECRET_VALUE=$(aws secretsmanager get-secret-value \
    --profile "$archive_from" \
    --region "$region" \
    --secret-id "$from_secret" \
    --query 'SecretString' \
    --output text)
   
    if [ -z "$SECRET_VALUE" ]; then
        echo "Error: Secret value could not be retrieved or is empty."
        exit 1
    fi

    aws secretsmanager create-secret \
    --profile "$archive_to" \
    --region "$region" \
    --name "$to_secret" \
    --secret-string "$SECRET_VALUE" \
    --kms-key-id "$kms_key_id"

    SECRET_VALUE=""
}

cat <<'END_TEXT'

***************************
SSM Secrets
***************************

END_TEXT

read -p "Would you like to copy any secrets? (y): " copy
if [ "$copy" == "y" ]; then 

cat <<'END_TEXT'

Below is a list of Secrets Manager secrets. You can copy all the secrets or individual
secrets based on the secret name. If encrypted, the KMS key ID is listed as well
and access to the KMS key is required to decrypted and transfer the secret to the
new account.

END_TEXT

echo "Secrets in source account:"
echo ""
aws secretsmanager list-secrets --query "SecretList[*].[Name, KmsKeyId]" --output text \
 --profile $archive_from --region $region

echo ""
from_secret="all"
echo ""
echo "Key ARNs and Aliases (one command for all this data: #awswishlist):"
echo ""

aws kms list-aliases --profile $kms_profile --region $region \
    | jq -r --arg region "$region" \
    --arg accountid "$(aws sts get-caller-identity --profile $kms_profile --query Account --output text)" \
    '.Aliases[] | select(.TargetKeyId) | "arn:aws:kms:" + $region + ":" + $accountid + ":key/" + .TargetKeyId + " " + .AliasName'

read -p "Enter KMS key ARN (only, not alias) to use to encrypt secrets in target account: " new_key_id

while [[ -n $from_secret ]]; do
   read -p "Enter the secret name you want to archive or all. Enter to continue: " from_secret
   if [[ -n $from_secret ]]; then
     if [ "$from_secret" == "all" ]; then

         SECRETS=$(aws secretsmanager list-secrets --query 'SecretList[*].Name' --profile $archive_from --region $region --output text)
         for from_secret in $SECRETS; do
           to_account=$(aws sts get-caller-identity --query Account --output text --profile $archive_from)
           to_secret='archive-'$to_account'-'$from_secret

           echo "from_secret: $from_secret"
           echo "to_secret: $to_secret"
           echo "archive_from: $archive_from"
           echo "archive_to: $archive_to"
           echo "region: $region"
           echo "new_key_id: $new_key_id"

           if [[ -z "$from_secret" ]]; then echo "from_secret is not set"; exit 1; fi
           if [[ -z "$to_secret" ]]; then echo "from_secret is not set"; exit 1; fi
           if [[ -z "$archive_from" ]]; then echo "from_secret is not set"; exit 1; fi
           if [[ -z "$archive_to" ]]; then echo "from_secret is not set"; exit 1; fi
           if [[ -z "$region" ]]; then echo "from_secret is not set"; exit 1; fi
           if [[ -z "$new_key_id" ]]; then echo "new_key_id is not set"; exit 1; fi

           archive_secret "$from_secret" "$to_secret" "$archive_from" "$archive_to" "$region" "$new_key_id"
         done
         from_secret=""
     else
       read -p "Enter the secet name in the destination account:" to_secret
       archive_secret $from_secret $to_secret $archive_from $archive_to $region $new_key_id
    fi
  fi

done


fi #end if copy
copy=""

