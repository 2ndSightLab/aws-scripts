#!/bin/bash
processor=$1

echo "*** download aws cli***"
if [ "$processor" == "x86" ]; then
	curl 'https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip' -o 'awscli.zip' -s 
else

        curl 'https://awscli.amazonaws.com/awscli-exe-linux-aarch64.zip' -o 'awscli.zip' -s
fi

echo "*** unzip aws cli***"
unzip -q awscli.zip

echo "*** install aws cli***"
sudo ./aws/install --update
rm awscli.zip

echo "done ok"
read ok

rm -rf aws
history -c
