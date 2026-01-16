#!/bin/bash
echo '************************************'
echo 'Install Docker'
echo '************************************'
sudo yum install -y docker
sudo usermod -a -G docker ec2-user
sudo systemctl start docker

history -c
