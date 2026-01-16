#!/bin/bash

#supposed instructions for python 3.9 but doesn't work
#sudo yum -y install gcc openssl-devel bzip2-devel libffi-devel
#cd /opt
#sudo wget https://www.python.org/ftp/python/3.9.4/Python-3.9.4.tgz
#sudo tar xzf Python-3.9.5.tgz
#cd Python-3.9.5
#sudo ./configure --enable-optimizations
#sudo make altinstall
#sudo rm -f /opt/Python-3.9.5.tgz
#python3.9 -V
#python3 -v
#pip3 -v
#which python3.9

echo '****Install Python3****'
sudo yum list python3*
sudo yum install python3 -y -q
sudo yum install python3-setuptools -y -q

echo '****Install pip3****'
python3 -m pip install -U pip --user

echo \" \" >> ~/.bash_profile

export PATH=LOCAL_PATH:$PATH

echo \"PATH=$PATH:/usr/lib64/python3.7\" >> ~/.bash_profile
export PATH=\"$PATH:/user/lib64/python3.7\"

echo 'alias python=python3' >> ~/.bashrc
echo 'alias pip3=pip3.7' >> ~/.bashrc
echo 'alias pip=pip3' >> ~/.bashrc
source ~/.bashrc

history -c
