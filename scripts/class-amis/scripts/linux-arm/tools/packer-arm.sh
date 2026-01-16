#!/bin/bash
echo '************************************'
echo 'Install Packer'
echo '************************************'

function get_ssm_param_value(){ echo $(aws ssm get-parameter --query "Parameter.Value" --with-decryption --name $1 | sed 's/"//g'); }

version=$(get_ssm_param_value ami.builder.packer.version)
echo "packer version: "$version

arch=$(get_param ami-builder-pt-linux-arch)
echo "arch: " arch

packerfile='packer_'$version'_linux_arm64.zip'

downloadurl='https://releases.hashicorp.com/packer/'$version'/'$packerfile

echo '**** Install packer version '$version' from '$downloadurl' ****'
cd /home/ec2-user/tools/downloads
wget $downloadurl
ls
unzip $packerfile
sudo mv packer /usr/local/bin/
sudo chmod +x /usr/local/bin/packer
#rm $packerfile
history -c

