#!/bin/bash
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
