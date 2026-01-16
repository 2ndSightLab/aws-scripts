#!/bin/bash
function get_ssm_param(){ echo $(aws ssm get-parameter --name $1); }
function get_ssm_param_value(){ echo $(jq -r .Parameter.Value <<< $1); }

version=$(get_ssm_param ami-builder-packer-version)
version=$(get_ssm_param_value "$version")
echo "packer version: "$version

packerfile='packer_'$version'_linux_amd64.zip'
downloadurl='https://releases.hashicorp.com/packer/'$version'/'$packerfile

echo '**** Install packer version '$version' from '$downloadurl' ****'
cd /home/ec2-user/tools/downloads
wget $downloadurl
ls
unzip $packerfile
sudo mv packer /usr/sbin/
sudo chmod +x /usr/sbin/packer
rm $packerfile
history -c
echo "packer version installed"
packer --version

