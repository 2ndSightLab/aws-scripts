image_id=$1
account_to_share_with=$2

aws ec2 modify-image-attribute \
    --image-id $image_id \
    --launch-permission "Add=[{UserId=$account_to_share_with}]"
