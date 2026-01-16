#!/bin/bash
echo '************************************'
echo 'Sync code from S3'
echo '************************************'

aws sts get-caller-identity

function get_ssm_param_value(){ echo $(aws ssm get-parameter --query "Parameter.Value" --with-decryption --name $1 | sed 's/"//g'); }

bucket=$(get_ssm_param_value "ami.builder.bucket")
echo $bucket

#bucket passed through env var set in packer
cd /home/ec2-user/tools
aws s3 sync 's3://'$bucket'/repo/' .
sudo chmod -R 700 .
sudo chown -R ec2-user .
history -c

