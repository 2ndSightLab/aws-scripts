#!/bin/bash


function get_ssm_param(){ echo $(aws ssm get-parameter --name $1); }
function get_ssm_param_value(){ echo $(jq -r .Parameter.Value <<< $1); }

version=$(get_ssm_param ami-builder-helm-version)
version=$(get_ssm_param_value "$version")
echo "helm version: "$version

file='helm-'$version'-linux-arm64.tar.gz'
url='https://get.helm.sh/'$file' -s -o '$file

echo '**** Install helm version '$version ' from '$url ' ****'
cd /home/ec2-user/tools/downloads
curl $url
tar -zxvf $file
chmod +x ./linux-arm64/helm
sudo mv ./linux-arm64/helm /usr/local/bin/helm
rm -rf $file
