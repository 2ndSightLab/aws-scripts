#!/bin/bash

#run s3sync.sh first
echo "*************************"
echo "***install jsbeautifier***"
echo "*************************"
pip install jsbeautifier

echo "*************************"
echo "***install git-secrets***"
echo "*************************"
cd /home/ec2-user/tools/scans/git-secrets
sudo make install

echo "************************"
echo "***install LinkFinder***"
echo "************************"
cd /home/ec2-user/tools/scans/LinkFinder/
python setup.py install --user
pip3 install --user -r requirements.txt

echo "**********************"
echo "****install dnslib****"
echo "**********************"
pip3 install --user dnslib

echo "*********************"
echo "****install flask****"
echo "*********************"
pip3 install --user flask
pip3 install --user flask_cors

echo "**********************"
echo "***** Sublister ******"
echo "**********************"
pip3 install /home/ec2-user/tools/scans/Sublist3r/ -r /home/ec2-user/tools/scans/Sublist3r/requirements.txt

rm -rf aws
history -c
