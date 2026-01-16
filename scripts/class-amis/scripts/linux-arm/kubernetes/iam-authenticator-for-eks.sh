#!/bin/bash

arch='arm64'
version='1.19.6'
file='aws-iam-authenticator'
url='https://amazon-eks.s3.us-west-2.amazonaws.com/'$version'/2021-01-05/bin/linux/'$arch'/'$file
checksum=$file'.sha256'
checksum_url='https://amazon-eks.s3.us-west-2.amazonaws.com/'version'/2021-01-05/bin/linux/'$arch'/'$checksum
exec_dir=/usr/local/bin

echo '**** Install '$file ' version '$version' from '$url' ****'
cd /home/ec2-user/tools/downloads
curl -o $file -s $url
curl -o $checksum -s $checksum_url 
openssl sha1 -sha256 $file
sudo chmod +x ./$file
sudo cp ./$file $exec_dir
rm $checksum

history -c

