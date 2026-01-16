#!/bin/sh
function get_ssm_param(){ echo $(aws ssm get-parameter --name $1); }
function get_ssm_param_value(){ echo $(jq -r .Parameter.Value <<< $1); }

version=$(get_ssm_param ami-builder-kubectl-version)
version=$(get_ssm_param_value "$version")
echo "kubectl version: "$version

url='https://storage.googleapis.com/kubernetes-release/release/'$version'/bin/linux/arm64/kubectl' 

cd /home/ec2-user/tools/downloads
echo '**** Install kubectl version: '$version' from '$url' ****'
curl -LO -s $url
chmod +x ./kubectl
sudo mv ./kubectl /usr/local/bin/kubectl
history -c

