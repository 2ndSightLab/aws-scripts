#!/bin/bash -e
archive_bucket(){
   from_bucket="$1"
   to_bucket="$2"
   archive_to="$3"
   region="$4"
   new_key_id="$5"

   if aws s3api list-buckets --profile "${archive_to}" --region "${region}" \
         --query "Buckets[?Name=='${to_bucket}'].Name" --output text | grep -q "${to_bucket}"; then

      echo "Bucket: $to_bucket exists"

   else
      read -p "Bucket: $to_bucket does not exist in the destination account. Do you want to create it?"

      aws s3api create-bucket \
          --bucket "${to_bucket}" \
          --region "${region}" \
          --profile "${archive_to}" \
          --create-bucket-configuration LocationConstraint="${region}"
   fi

   key_id=$(aws s3api get-bucket-encryption \
      --bucket "${to_bucket}" \
      --profile "${archive_to}" \
      --region "${region}")

   #the jq filter has to be on one line apparently or Gemini cannot tell me how to break it up without causing an error.
   key_id=$(echo "${key_id_raw_output}" | jq -r '.ServerSideEncryptionConfiguration.Rules[] | select(.ApplyServerSideEncryptionByDefault.SSEAlgorithm == "aws:kms") | .ApplyServerSideEncryptionByDefault.KMSMasterKeyID')

   echo "key_id on bucket: $key_id"

   if [[ -z "${key_id}" ]]; then

     if [[ -z "$new_key_id" ]]; then
       read -p "KMS key ID not found on to_bucket $to_bucket. Enter the ARN or ID of the KMS Key to use for encryption: " new_key_id
     fi
     echo "Adding encryption to bucket using key: $new_key_id"
     aws s3api put-bucket-encryption \
        --bucket "${to_bucket}" \
        --profile "${archive_to}" \
        --region "${region}" \
        --server-side-encryption-configuration '{
        "Rules": [
        {
          "ApplyServerSideEncryptionByDefault": {
            "SSEAlgorithm": "aws:kms",
            "KMSMasterKeyID": "'"${new_key_id}"'"
          }
        }
        ]
        }'

   fi

   #we need to use the role in the to account and make sure it has access to the 
   #bucket in the from account and the kms key used to encrypt the data
   aws s3 sync s3://$from_bucket/ s3://$to_bucket/ \
         --profile $archive_to \
         --region $region
}

cat <<'END_TEXT'

***************************
S3 Buckets 
***************************
END_TEXT

read -p "Would you like to copy any S3 buckets? (y): " copy

if [ "$copy" == "y" ]; then

read -p "Would you like to see the required IAM, KMS and S3 policies to transfer an encrypted bucket? (y): " v

if [ "$v" == "y" ]; then

cat <<'END_TEXT' 
Add IAM policy for archive admin role in the from_account (limit further if needed):
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "s3:ListAllMyBuckets",
                "s3:ListBucket",
                "s3:GetBucketLocation",
                "s3:GetObject",
                "s3:PutObject"
            ],
            "Resource": [
                "arn:aws:s3:::*",
                "arn:aws:s3:::*/*"
            ]
        }
    ]
}

Add bucket policy for each bucket in the from account:

{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": {
                "AWS": "<AccountA-IAM-ROLE-ARN>" 
            },
            "Action": [
                "s3:ListBucket",
                "s3:GetObject"
            ],
            "Resource": [
                "arn:aws:s3:::YOUR_BUCKET_NAME",
                "arn:aws:s3:::YOUR_BUCKET_NAME/*"
            ]
        }
    ]
}

If the bucket is encrypted make sure the key policy grants access to the archive admin role.
The permissions need to be added to the keys on buckets in both accounts. In addition,
the role executing the sync command needs KMS permissions in the IAM role policy.

{
    "Version": "2012-10-17",
    "Id": "key-policy-for-s3-role-access",
    "Statement": [
        {
            "Sid": "Allow role to encrypt and decrypt data in S3",
            "Effect": "Allow",
            "Principal": {
                "AWS": "arn:aws:iam::<AWS-ACCOUNT-ID>:role/<ROLE-NAME>"
            },
            "Action": [
                "kms:Encrypt",
                "kms:Decrypt",
                "kms:ReEncrypt*",
                "kms:GenerateDataKey*",
                "kms:DescribeKey"
            ],
            "Resource": "*" 
        }
    ]
}


END_TEXT
fi

read -p "Do you want to see the list of S3 buckets? (y): " view
if [ "$view" == "y" ]; then

cat <<'END_TEXT'

Below is a list of S3 Buckets. You can copy all the buckets or individual
buckets based on the bucket name. You will need permission to use the KMS key 
if one exists to decrypt the contents of the bucket.

END_TEXT

  for bucket_name in $(aws s3api list-buckets --query "Buckets[].Name" --output text --profile $archive_from --region $region); do 
    echo "Bucket: ${bucket_name}" 
    encryption_info=$(aws s3api get-bucket-encryption --bucket "${bucket_name}" --profile $archive_from --region $region)
    if [[ $? -eq 0 ]]; then 
       kms_key_id=$(echo "${encryption_info}" | \
       jq -r '.ServerSideEncryptionConfiguration.Rules[0].ApplyServerSideEncryptionByDefault.KMSMasterKeyID')
    if [ "${kms_key_id}" == "null" ]; then kms_key_id=""; fi
    echo "  KMS Key ID: ${kms_key_id}" 
   fi
  done
  echo ""

fi

from_bucket="all"
echo ""
echo "Key ARNs and Aliases (one command for all this data: #awswishlist): "
echo ""

aws kms list-aliases --profile $kms_profile --region $region \
    | jq -r --arg region "$region" \
    --arg accountid "$(aws sts get-caller-identity --profile $kms_profile --query Account --output text)" \
    '.Aliases[] | select(.TargetKeyId) | "arn:aws:kms:" + $region + ":" + $accountid + ":key/" + .TargetKeyId + " " + .AliasName'

read -p "Enter KMS key ARN (only, not alias) to use to encrypt buckets in target account: " new_key_id

while [[ -n $from_bucket ]]; do
   read -p "Enter the bucket name you want to archive or all. Enter to continue: " from_bucket
   if [[ -n $from_bucket ]]; then
     if [ "$from_bucket" == "all" ]; then

         BUCKETS=$(aws s3api list-buckets --profile $archive_from --region $region  --query "Buckets[].Name" --output text)
         for from_bucket in $BUCKETS; do
           to_bucket='archive-'$from_bucket
           archive_bucket $from_bucket $to_bucket $archive_to $region $new_key_id
         done
         from_bucket=""
     else
       read -p "Enter the bucket to which you want to copy the files in the archive_to account: " to_bucket
       archive_bucket $from_bucket $to_bucket $archive_to $region $new_key_id
    fi
  fi
   
done

fi #end copy
copy=""
