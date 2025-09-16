#!/bin/bash -e

cat <<'END_TEXT'

***************************
TEST EC2 AMI (Amamazon Machine Image)
***************************

It takes too long for an AMI to become available 
for the archive script most of the time so 
this separate script can be used to test that a single
AMI is working once it becomes available.

It would be nice if AWS would speed up the AMI
creation process ;-)

AWS CLI profiles in this account:

END_TEXT

aws configure list-profiles

read -p "Enter the profile you want to use: " profile
read -p "Enter the region you want to use: " region
read -p "Enter the KMS profile that can list available KMS keys to encrypt the test instance: " kms_profile

read -p "Do you want to see a list of images in the from account? (y): " view
if [ "$view" == "y" ]; then

cat <<'END_TEXT'
Below is a list of Amazon Machine Images in this account.

END_TEXT

  aws ec2 describe-images \
  --owners self \
  --profile $profile \
  --region $region \
  --query 'Images[*].{Name: Name, ImageId: ImageId, Snapshots: BlockDeviceMappings[?Ebs.Encrypted==`true`].Ebs.SnapshotId}' \
  --output json \
 | jq -r '.[] | "\(.Name),\(.ImageId),\(.Snapshots[] // "N/A")" ' \
 | while IFS=, read -r ami_name ami_id snapshot_id; do
    if [[ "${snapshot_id}" == "N/A" ]]; then
        echo "AMI Name: ${ami_name}, AMI ID: ${ami_id}, KMS Key ID: No encryption/KMS key used"
    else
        kms_key_id=$(aws ec2 describe-snapshots \
          --snapshot-ids "${snapshot_id}" \
          --profile $profile \
          --region $region \
          --query "Snapshots[*].KmsKeyId" \
          --output text 2>/dev/null)
        if [[ -z "${kms_key_id}" ]]; then
            kms_key_id="Default/AWS managed key"
        fi
        echo "AMI Name: ${ami_name}, AMI ID: ${ami_id}, KMS Key ID: ${kms_key_id}"
    fi
  done

  echo ""
fi

read -p  "Done displaying image names. Copy AMI id you want to test: " AMI_ID


   echo ""
   echo "EC2 SSH keys in the to account:"
   echo ""
   aws ec2 describe-key-pairs  --query 'KeyPairs[*].KeyName' \
     --profile $profile --region $region --output text
   echo ""
   read -p "Enter the name of your SSH key pair or list to see a list of key pairs: " KEY_PAIR
   echo ""
   echo "Security groups in the to account:"
   echo ""
   aws ec2 describe-security-groups --query "SecurityGroups[*].[GroupId,GroupName]" --output text \
      --region $region --profile $profile
   echo ""
   read -p "Enter the Security Group ID (e.g., sg-xxxxxxxxxxxxxxxxx): " SG_ID
   echo ""
   echo "Subnets in the to account:"
   aws ec2 describe-subnets --profile $profile --region $region \
      --query "Subnets[*].{ID:SubnetId,Name:Tags[?Key=='Name']|[0].Value}" --output text
   echo ""
   read -p "Enter the Subnet ID (e.g., subnet-xxxxxxxxxxxxxxxxx): " SUBNET_ID
   echo ""
   echo "Key ARNs and Aliases (one command for all this data: #awswishlist):"
   echo ""

   aws kms list-aliases --profile $kms_profile --region $region \
    | jq -r --arg region "$region" \
    --arg accountid "$(aws sts get-caller-identity --profile $kms_profile --query Account --output text)" \
    '.Aliases[] | select(.TargetKeyId) | "arn:aws:kms:" + $region + ":" + $accountid + ":key/" + .TargetKeyId + " " + .AliasName'

   echo ""  
   read -p "Enter the KMS Key ARN for EBS encryption in the destination account: " KMS_KEY
        
   read -p "Do you want to see valid instances types for this ami? (y): " show
   if [ "$show" == "y" ]; then

       aws ec2 describe-instance-types \
       --filters "Name=processor-info.supported-architecture,\
       Values=$(aws ec2 describe-images --image-ids "$AMI_ID" \
       --query 'Images[0].Architecture' --output text \
       --profile "$profile")" --query 'InstanceTypes[*].InstanceType' \
       --output json --region $region --profile "$profile" | jq -r '.[]'

       echo ""
   fi

   read -p "Enter desired image type (e.g., t2.micro, t2.medium): " instance_type

   block_device_mappings='[{"DeviceName": "/dev/xvda","Ebs": {"Encrypted": true, "KmsKeyId": "'$KMS_KEY'"}}]'
   echo "block_device_mappings: $block_device_mappings"

   echo "Launching instance..."

   aws ec2 run-instances --image-id "$AMI_ID" \
    --instance-type "$instance_type" --key-name "$KEY_PAIR" \
    --security-group-ids "$SG_ID" \
    --subnet-id "$SUBNET_ID" \
    --block-device-mappings "$block_device_mappings" \
    --output text \
    --region $region \
    --profile "$profile"

   echo "Instance launched. Wait for the instance to become available to ensure it works and test access as needed."

