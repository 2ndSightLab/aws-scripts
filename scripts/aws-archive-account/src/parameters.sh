#!/bin/bash -e

archive_parameter(){
 local from_parameter="$1"
 local to_parameter="$2"
 local archive_from="$3"
 local archive_to="$4"
 local region="$5"
 local kms_key_id="$6"

 local PARAMETER_VALUE=""

 PARAMETER_VALUE=$(aws ssm get-parameter \
    --profile "$archive_from" \
    --region "$region" \
    --name "$from_parameter" \
    --with-decryption \
    --query 'Parameter.Value' \
    --output text)
   
    if [ -z "$PARAMETER_VALUE" ]; then
        echo "Error: Parameter value could not be retrieved or is empty."
        echo "Does the AWS CLI Profile: $archive_from have permission to decrypt the parameter?"
        exit 1
    fi

    aws ssm put-parameter \
    --profile "$archive_to" \
    --region "$region" \
    --name "$to_parameter" \
    --value "$PARAMETER_VALUE" \
    --key-id "$kms_key_id" \
    --overwrite \
    --type "SecureString"

    if [ $? -ne 0 ]; then
      echo "Error: Failed to create parameter $to_parameter"
      exit 1
    fi

    PARAMETER_VALUE=""
}

cat <<'END_TEXT'

***************************
SSM Secrets
***************************

END_TEXT

read -p "Would you like to copy any parameters? (y): " copy
if [ "$copy" == "y" ]; then 

cat <<'END_TEXT'

Below is a list of Parameters. You can copy all the parameters or individual
parameters based on the parameter name. If encrypted, the KMS key ID is listed as well
and access to the KMS key is required to decrypted and transfer the parameter to the
new account.

END_TEXT

echo "Parameters in source account and KMS key id:"
echo ""

aws ssm describe-parameters \
    --query 'Parameters[*].{Name:Name,KmsKeyId:KeyId}' \
    --output json \
    --profile $archive_from \
    --region $region | jq -r '.[] | [.Name, .KmsKeyId] | @tsv'

echo ""
from_parameter="all"
echo ""
echo "Key ARNs and Aliases (one command for all this data: #awswishlist):"
echo ""

aws kms list-aliases --profile $kms_profile --region $region \
    | jq -r --arg region "$region" \
    --arg accountid "$(aws sts get-caller-identity --profile $kms_profile --query Account --output text)" \
    '.Aliases[] | select(.TargetKeyId) | "arn:aws:kms:" + $region + ":" + $accountid + ":key/" + .TargetKeyId + " " + .AliasName'

read -p "Enter KMS key ARN (only, not alias) to use to encrypt parameters in target account: " new_key_id

while [[ -n $from_parameter ]]; do
   read -p "Enter the parameter name you want to archive or all. Enter to continue: " from_parameter
   if [[ -n $from_parameter ]]; then
     if [ "$from_parameter" == "all" ]; then

         PARAMETERS=$(aws ssm describe-parameters --query 'Parameters[].Name' --output text \
            --profile $archive_from --region $region | tr '\t' '\n')

         for from_parameter in $PARAMETERS; do
           to_account=$(aws sts get-caller-identity --query Account --output text --profile $archive_from)
           to_parameter='/archive/'$to_account''$from_parameter

           echo "from_parameter: $from_parameter"
           echo "to_parameter: $to_parameter"
           echo "archive_from: $archive_from"
           echo "archive_to: $archive_to"
           echo "region: $region"
           echo "new_key_id: $new_key_id"

           if [[ -z "$from_parameter" ]]; then echo "from_parameter is not set"; exit 1; fi
           if [[ -z "$to_parameter" ]]; then echo "from_parameter is not set"; exit 1; fi
           if [[ -z "$archive_from" ]]; then echo "from_parameter is not set"; exit 1; fi
           if [[ -z "$archive_to" ]]; then echo "from_parameter is not set"; exit 1; fi
           if [[ -z "$region" ]]; then echo "from_parameter is not set"; exit 1; fi
           if [[ -z "$new_key_id" ]]; then echo "new_key_id is not set"; exit 1; fi

           archive_parameter "$from_parameter" "$to_parameter" "$archive_from" "$archive_to" "$region" "$new_key_id"
         done
         from_parameter=""
     else
       read -p "Enter the parameter name in the destination account:" to_parameter
       archive_parameter $from_parameter $to_parameter $archive_from $archive_to $region $new_key_id
    fi
  fi

done


fi #end if copy
copy=""

