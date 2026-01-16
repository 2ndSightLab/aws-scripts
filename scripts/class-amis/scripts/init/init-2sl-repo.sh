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

function get_ssm_param(){ echo $(aws ssm get-parameter --query "Parameter.Value" --with-decryption --name $1 | sed 's/"//g'); }

bucket=$(get_ssm_param ami.builder.bucket --query Name --output text)
#bucket=$(get_ssm_param_value $bucket_param)
bucket_repo_folder='s3://'$bucket'/repo' 
echo $bucket_repo_folder" ok?";read ok

function mdir {
    echo "Deleting and making directory $1 OK? (ctrl-c to exit)"
    read ok
    rm -rf $1
    mkdir $1
}

repodir="$HOME/repo"
toolsdir="$repodir/tools"
d2sl="$toolsdir/2sl"

mdir "$repodir"
mdir "$toolsdir"
mdir "$d2sl"

ls $toolsdir
echo "Directories OK? Ctrl-C to exit"
read ok

cd $d2sl
git clone https://github.com/2ndSightLab/2sl-recon.git
git clone https://github.com/2ndSightLab/2sl-enum.git
git clone https://github.com/2ndSightLab/2sl-lists.git
git clone https://github.com/2ndSightLab/2sl-fuzz.git

echo "Removing git files from "$(pwd)" OK? Ctrl-C to exit"
read ok

find . \( -name ".git" -o -name ".gitignore" -o -name ".gitmodules" -o -name ".gitattributes" \) -exec rm -rf -- {} +

echo "Checking contents:"
ls

echo "uploading to S3"
aws s3 sync $toolsdir $bucket_repo_folder                                 
