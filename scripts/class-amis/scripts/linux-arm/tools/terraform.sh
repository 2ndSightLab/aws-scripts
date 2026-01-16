#!/bin/sh
echo '************************************'
echo 'Install terraform'
echo '************************************'
function get_ssm_param_value(){ echo $(aws ssm get-parameter --query "Parameter.Value" --with-decryption --name $1 | sed 's/"//g'); }

version=$(get_ssm_param_value ami.builder.terraform.version)
echo "terraform version: "$version

file='terraform_'$version'_linux_arm64.zip'
url='https://releases.hashicorp.com/terraform/'$version'/'$file
echo '**** Install terraform version '$version' from '$url '****'

cd /home/ec2-user/tools/downloads
wget $url
unzip $file
sudo mv terraform /usr/local/bin/
sudo chmod +x /usr/local/bin/terraform
rm $file
history -c

