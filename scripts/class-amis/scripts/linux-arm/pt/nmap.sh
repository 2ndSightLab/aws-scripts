#!/bin/bash


function get_ssm_param_value(){ echo $(aws ssm get-parameter --query "Parameter.Value" --with-decryption --name $1 | sed 's/"//g'); }

version=$(get_ssm_param_value ami.builder.nmap.version)

dir='/home/ec2-user/tools/downloads/'
cd $dir
f='nmap-'$version
dir=$dir$f
file=$f'.tar.bz2'
url='https://nmap.org/dist/'$file

#This should be on the tools ami
#echo '**** Install python_devel ****'
#sudo yum install python3-devel -y

echo '**** Install nmap***'
curl -s $url --output $file
bzip2 -cd $file | tar xvf -
cd $dir
./configure || echo "nmap configure failed"
make || echo "nmap make failed"
sudo make install || echo "nmap make install failed"

history -c
