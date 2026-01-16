i#!/bin/bash
echo "jq version:"
jq --version

echo "Assume Packer Role"
#To get out of packer role unset credentials
#unset AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY AWS_SESSION_TOKEN
echo "------------------------------------------------"
assumerole="arn:aws:iam::453844007816:role/2sl-packer-role"
assumerolejson=$(aws sts assume-role --role-arn $assumerole  --role-session-name 2SLAMIBUILDERSESSION)
#echo $assumerolejson; echo "Assume role ok?"; read ok

echo "Set env var credentials and check identity"
echo "------------------------------------------------"
id=$(echo $assumerolejson | jq .Credentials.AccessKeyId | sed 's/"//g')
key=$(echo $assumerolejson | jq .Credentials.SecretAccessKey | sed 's/"//g')
session=$(echo $assumerolejson | jq .Credentials.SessionToken | sed 's/"//g')
#echo $id; echo $key; echo $session; echo "Values ok?"; read ok

export AWS_ACCESS_KEY_ID=$id
export AWS_SECRET_ACCESS_KEY=$key
export AWS_SESSION_TOKEN=$session
export AWS_REGION=us-east-2

aws sts get-caller-identity
echo "Idenity ok?"; read ok

type="SecureString"
keyid="arn:aws:kms:us-east-2:639060417242:key/0e6a08d2-164b-487c-9c2f-ae4ec2940cbd"

#eventualy set these dynamically based on output from cfn scripts for builder
#param='ami-builder-region'
#value='us-east-2'
#echo $param": "$value
#aws ssm put-parameter --name $param --value=$value --type=$type --key-id=$keyid --overwrite

#param='ami-builder-vpc-id'
#value='vpc-0143be55f7b069987'
#echo $param": "$value
#aws ssm put-parameter --name $param --value=$value --type=$type --key-id=$keyid --overwrite

#param='ami-builder-subnet-id'
#value='subnet-0e63e9d46c9613310'
#echo $param": "$value
#aws ssm put-parameter --name $param --value=$value --type=$type --key-id=$keyid --overwrite

#param='ami-builder-kms-key-id'
#value='89ae49d9-c7d3-4876-86aa-fa856a6855ad'
#echo $param": "$value
#aws ssm put-parameter --name $param --value=$value --type=$type --key-id=$keyid --overwrite

#param='ami-builder-iam-profile'
#echo 'The iam profile needs read only access to S3 to perform certain build tasks'
#value='packer-role'
#echo $param": "$value
#aws ssm put-parameter --name $param --value=$value --type=$type --key-id=$keyid --overwrite

param='ami.builder.terraform.version'
value=$(curl -s https://checkpoint-api.hashicorp.com/v1/check/terraform | jq -r -M '.current_version')
echo $value
echo $param": "$value
aws ssm put-parameter --name $param --value=$value --type=$type --key-id=$keyid --overwrite

param='ami.builder.helm.version'
value=$(curl -s https://github.com/helm/helm/releases | grep 'Helm v' | head -1 | sed 's/.*Helm v//' | sed 's/<.*//')
echo $param": "$value
aws ssm put-parameter --name $param --value=$value --type=$type --key-id=$keyid --overwrite

param='ami.builder.kube.ctl.version'
value=$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)
echo $param": "$value
aws ssm put-parameter --name $param --value=$value --type=$type --key-id=$keyid --overwrite

param='ami.builder.packer.version'
value=$(curl -s https://checkpoint-api.hashicorp.com/v1/check/packer | cut -f2 -d ',' | cut -d ":" -f2 | sed 's/"//g')
echo $param": "$value
aws ssm put-parameter --name $param --value=$value --type=$type --key-id=$keyid --overwrite

#get latest linux arm ami
param='ami.linux.arm.base.baseami.arm64'
arch='arm64'
value=$(aws ec2 describe-images \
    --owners amazon \
    --filters "Name=name,Values=amzn2-ami-hvm*" \
       "Name=root-device-type,Values=ebs" \
       "Name=architecture,Values=$arch" \
    --query 'Images[*].[ImageId,CreationDate,Name]' \
		--output text \
    | sort -r -k2 | head -1 | cut -f1)

value=$(echo $value | sed 's/ //g')
echo $param": "$value
read ok

aws ssm put-parameter --name $param --value=$value --type=$type --key-id=$keyid --overwrite

param='ami.linux.arm.base.baseami.x86_64'
arch='x86_64'
value=$(aws ec2 describe-images \
    --owners amazon \
    --filters "Name=name,Values=amzn2-ami-hvm*" \
       "Name=root-device-type,Values=ebs" \
       "Name=architecture,Values=$arch" \
    --query 'Images[*].[ImageId,CreationDate,Name]' \
		--output text \
    | sort -r -k2 | head -1 | cut -f1)
    
value=$(echo $value | sed 's/ //g')
echo $param": "$value
aws ssm put-parameter --name $param --value=$value --type=$type --key-id=$keyid --overwrite

param='ami.windows.base.baseami'
value=$( \
aws ec2 describe-images \
    --owners amazon \
    --filters \
       "Name=platform,Values=windows" \
       "Name=root-device-type,Values=ebs" \
    --query 'Images[*].[ImageId,CreationDate,Name]' \
    --output text \
    | grep -i 'English' | grep '2019' | grep -i 'Base' | grep -v Preview |grep -v Preview |  sort -r -k2 | head -1 | cut -f1)

value=$(echo $value | sed 's/ //g')
echo $param": "$value
aws ssm put-parameter --name $param --value=$value --type=$type --key-id=$keyid --overwrite

echo "Paramaters set"
