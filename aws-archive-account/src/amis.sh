#!/bin/bash -e

create_local_ami() {
  local ami_id="$1"
  local key_pair_name="$2"
  local security_group_id="$3"
  local subnet_id="$4"
  local kms_key="$5"
  local archive_to="$6" 
  local region="$7"
  local instance_size="$8"

   block_device_mappings='[{"DeviceName": "/dev/xvda","Ebs": {"Encrypted": true, "KmsKeyId": "'$KMS_KEY'"}}]'
   echo "block_device_mappings: $block_device_mappings"

   echo "Share ami: $AMI_ID"
   echo "key pair: $key_pair_name"
   echo "security group: $security_group_id"
   echo "subnet: $subnet_id"
   echo "ksm_key: $kms_key"
   echo "region: $region"

   if [[ -z "$instance_size" ]]; then 

     read -p "Do you want to see valid instances types for this ami? (y): " show
     if [ "$show" == "y" ]; then 
       aws ec2 describe-instance-types \
       --filters "Name=processor-info.supported-architecture,\
       Values=$(aws ec2 describe-images --image-ids "$ami_id" \
       --query 'Images[0].Architecture' --output text \
       --profile "$archive_to")" --query 'InstanceTypes[*].InstanceType' \
       --output json --region $region --profile "$archive_to" | jq -r '.[]'

       echo ""
     fi
  
     read -p "Enter desired image size (e.g., t2.micro, t2.medium): " instance_size

   fi

   echo "Launch instance from AMI: $ami_id"

   instance_id=$(launch_instance "$ami_id" "$key_pair_name" "$security_group_id" "$subnet_id" "$kms_key" "$archive_to" "$region" "$instance_size")

   if [[ "$instance_id" != i-* ]]; then
     echo "Error launching instance: $instance_id"
     exit 1
   else
     echo "Launched instance: $instance_id"
   fi

   instance_id=$(check_status "$instance_id" "$archive_to" "$region")

   if [[ "$instance_id" != i-* ]]; then
     echo "Error launching instance: $instance_id"
     exit 1
   else
     echo "Launched instance: $instance_id"
     echo "Stop the instance"
     aws ec2 stop-instances --instance-ids $instance_id --profile $archive_to --region $region
     read -p "Enter new image name: " iname
     read -p "Enter description: " idesc

     echo "Waiting for instance to stop"
     aws ec2 wait instance-stopped --instance-ids $instance_id --profile $archive_to --region $region

     NEW_AMI=$(aws ec2 create-image \
     --instance-id $instance_id \
     --name "$iname" \
     --description "$idesc" \
     --query 'ImageId' \
     --profile "$archive_to" \
     --region "$region" \
     --output text)

     echo "Image created: $NEW_AMI"

cat <<'END_TEXT'

        I tried to add some code here to wait for the ami
        to become available and then test it, 
        however it takes so long for the AMI to become 
        available that the script always times out or 
        is difficult to test. To simplify things I 
        created a separate script for testing AMIs. 
        Wait until the AMI status changes to  
        Available and then run the script src/test-ami.sh.
        Maybe I'll play around with this more later or 
        AWS will make AMI creation faster.

END_TEXT

     test='n'
     #read -p "Do you want to test the image? (y):" test
     if [ "$test" == "y" ]; then

        echo "Waiting for AMI to become available..."
        NEW_AMI=$(wait_for_ami $NEW_AMI)

        if [[ "$NEW_AMI" != ami-* ]]; then
          echo "Error checking status of ami: $NEW_AMI"
          exit 1
        else
          echo "Status available for ami: $NEW_AMI" 
        fi
 
        new_ami_instance_id=$(launch_instance "$NEW_AMI" "$key_pair_name" "$security_group_id" "$subnet_id" "$kms_key" "$archive_to" "$region" "$instance_size")

        if [[ "$new_ami_instance_id" != i-* ]]; then
          echo "Error launching test instance: $new_ami_instance_id"
          exit 1
        else
          echo "Launched instance: $new_ami_instance_id"
        fi

        echo "Checking status of test instance: $new_ami_instance_id"
        new_ami_instance_id=$(check_status "$new_ami_instance_id" "$archive_to" "$region")

        if [[ "$new_ami_instance_id" != i-* ]]; then
          echo "Error checking status of instance: $new_ami_instance_id"
          exit 1
        else
          echo "Status OK for  instance: $new_ami_instance_id" 
        fi
        echo "Enter stop to stop the new instance"
        echo "Enter terminate to terminate the new instance"
        echo "Enter to leave the instance running"
        read -p "Enter status: " status

        if [ "$status" == "stop" ]; then
          aws ec2 stop-instances --instance-ids $new_ami_instance_id \
            --profile $archive_from --region $region
        fi

        if [ "$status" == "terminate" ]; then 
          aws ec2 terminate-instances --instance-ids $new_ami_instance_id \
          --profile $archive_from --region $region
        fi

        echo "Terminating the instance using transferred AMI: $ami_id"
        aws ec2 terminate-instances --instance-ids $instance_id \
         --profile $archive_from --region $region
    
      fi
   fi
}

wait_for_ami(){
  AMI_ID="$1"  

  local MAX_ATTEMPTS=240
  local DELAY=15 
  local AMI_STATE=""

  echo "Waiting for AMI $AMI_ID to become available."

  ATTEMPT=0
  while [ $ATTEMPT -lt $MAX_ATTEMPTS ]; do

    AMI_STATE=$(aws ec2 describe-images \
    --image-ids "$AMI_ID" \
    --query 'Images[0].State' \
    --output text \
    --profile $archive_to \
    --region $region)

    if [ $? -eq 0 ] && [ "$AMI_STATE" == "available" ]; then
      echo $AMI_ID
      return 0
    fi

    if [ "$AMI_STATE" == "failed" ]; then
      echo "Error: AMI $AMI_ID id in failed state. Exit."
      exit 1
    fi

    sleep $DELAY

    ATTEMPT=$((ATTEMPT+1))

  done

  echo "Error: Max attempts exceeded for AMI $AMI_ID. Timed out."
  wait_more="y"
  while [ "wait_more" != "n" ]; do
    read -p "Do you want to continue waiting? (y/n)" wait_more
    if [ "$wait_more" == "y" ]; then
      wait_for_ami $AMI_ID
      wait_for_ami="n"
    fi
  done
}

check_status(){
    local instance_id="$1"
    local archive_to="$2"
    local region="$3"

    local COUNT=0
    local MAX_ATTEMPTS=60

    if [[ "$instance_id" != i-* ]]; then
      echo "Invalid instance ID: $instance_id"
      exit
    fi

    while true; do 

        if [ "$COUNT" -ge "$MAX_ATTEMPTS" ]; then
           echo "Error: Maximum attempts $MAX_ATTEMPTS reached. Instance not available or terminated."
           exit 1
        fi

        ((COUNT++))

        STATE=$(aws ec2 describe-instance-status \
        --instance-ids "$instance_id" \
        --include-all-instances \
        --query '[InstanceStatuses[0].InstanceState.Name, InstanceStatuses[0].InstanceStatus.Status]' \
        --output text \
        --region "$region" \
        --profile "$archive_to")

        read -r STATE STATUS <<< "$STATE"

        if [ "$STATE" == "terminated" ]; then
            echo "Instance started then terminated."
            echo "Does the profile $archive_to have permission to use key: $kms_key?"
            exit 1
        fi
 
        if [ "$STATE" == "running" ] && [ "$STATUS" == "ok" ]; then
          echo $instance_id
          break
        fi
                
        sleep 5
    done
}

launch_instance(){
  local ami_id="$1"
  local key_pair_name="$2"
  local security_group_id="$3"
  local subnet_id="$4"
  local kms_key="$5"
  local archive_to="$6"
  local region="$7"
  local instance_size="$8"

   instance_id=$(aws ec2 run-instances --image-id "$ami_id" \
    --instance-type "$instance_size" --key-name "$key_pair_name" \
    --security-group-ids "$security_group_id" \
    --subnet-id "$subnet_id" \
    --block-device-mappings "$block_device_mappings" \
    --query "Instances[0].InstanceId" \
    --output text \
    --region $region \
    --profile "$archive_to" 2>&1)
 
  echo "$instance_id"

}

share_ami(){
  local AMI_ID="$1"
  local to_account="$2"
  local archive_from="$3"
  local region="$4"

  echo "Share ami: $AMI_ID"
  
  aws ec2 modify-image-attribute --image-id $AMI_ID --launch-permission "Add=[{UserId=$to_account}]" \
           --profile $archive_from --region $region
  echo "Shared the AMI."
  echo "Status is pending...."
}


cat <<'END_TEXT'

***************************
EC2 AMIs (Amazon Machine Images)
***************************

END_TEXT


read -p "Do you want to copy any AMIs? (y): " copy
if [ "$copy" == "y" ]; then

read -p "Do you want to see a list of images in the from account? (y): " view
if [ "$view" == "y" ]; then

cat <<'END_TEXT'
Below is a list of Amazon Machine Images in this account which can be used to 
start new EC2 instances. Note that if the AMI is encrypted, the user trying
to start a new image from the AMI will need permission to use the associated
KMS key.

END_TEXT

  aws ec2 describe-images \
  --owners self \
  --profile $archive_from \
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
          --profile $archive_from \
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

echo "Done displaying image names."

AMI_ID="all"

while [[ -n "$AMI_ID" ]]; do

   read -p "Enter the AMI ID (not name) you want to archive or all. Enter to continue: " AMI_ID

   echo "Enter the values for the EC2 instance used to transfer the AMI ownership to the new account:"

   echo ""
   echo "EC2 SSH keys in the to account:"
   echo ""
   aws ec2 describe-key-pairs  --query 'KeyPairs[*].KeyName' \
     --profile $archive_to --region $region --output text
   echo ""
   read -p "Enter the name of your SSH key pair or list to see a list of key pairs: " KEY_PAIR
   echo ""
   echo "Security groups in the to account:"
   echo ""
   aws ec2 describe-security-groups --query "SecurityGroups[*].[GroupId,GroupName]" --output text \
      --region $region --profile $archive_to
   echo ""
   read -p "Enter the Security Group ID (e.g., sg-xxxxxxxxxxxxxxxxx): " SG_ID
   echo ""
   echo "Subnets in the to account:"
   aws ec2 describe-subnets --profile $archive_to --region $region \
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

   to_account=$(aws sts get-caller-identity --query Account --output text --profile $archive_to)

   if [[ -n $AMI_ID ]]; then
     if [ "$AMI_ID" == "all" ]; then

       #loop through all AMIs and share them
       aws ec2 describe-images --region "$region" --owners 'self' \
          --profile $archive_from
          --query 'Images[].ImageId' --output json | jq -r '.[]' | while read ami_id; do
          share_ami "$AMI_ID" "$to_account" "$archive_from" "$region"
       done
   
       #create local ami
       aws ec2 describe-images --region "$region" --owners 'self' \
          --profile $archive_from 
          --query 'Images[].ImageId' --output json | jq -r '.[]' | while read ami_id; do
       create_local_ami "$AMI_ID" "$KEY_PAIR" "$SG_ID" "$SUBNET_ID" "$KMS_KEY" "$archive_to" "$region"
     done

     else
    
       share_ami "$AMI_ID" "$to_account" "$archive_from" "$region"
       create_local_ami "$AMI_ID" "$KEY_PAIR" "$SG_ID" "$SUBNET_ID" "$KMS_KEY" "$archive_to" "$region"
     fi
   fi
done      

echo "Remember to test the AMIs! You can do that with the script src/test-ami.sh"
echo "After you verify the AMIs are good to go you can remove them deregister them in the from account."
echo ""
read -p "Enter to continue." ok


#end if copy....
fi

