assumerole="arn:aws:iam::453844007816:role/2sl-packer-role"
assumerolejson=$(aws sts assume-role --role-arn $assumerole  --role-session-name 2SLPACKERSESSION)

id=$(echo $assumerolejson | jq .Credentials.AccessKeyId | sed 's/"//g')
key=$(echo $assumerolejson | jq .Credentials.SecretAccessKey | sed 's/"//g')
session=$(echo $assumerolejson | jq .Credentials.SessionToken | sed 's/"//g')

export AWS_ACCESS_KEY_ID=$id
export AWS_SECRET_ACCESS_KEY=$key
export AWS_SESSION_TOKEN=$session
export AWS_REGION=us-east-2

ami_version_name="ami.windows.base-20220617-0707AMUTC"
image_id=$(aws ec2 describe-images --owners 453844007816 --filters Name="name",Values=$ami_version_name --query 'Images[*].[ImageId]' --output text)
echo $image_id

ssm_ami_latest='ami.linux.arm.base.latest'
kmskey='arn:aws:kms:us-east-2:639060417242:key/0e6a08d2-164b-487c-9c2f-ae4ec2940cbd'
aws ssm put-parameter --name $ssm_ami_latest --value $image_id --type SecureString --key-id $kmskey --overwrite

