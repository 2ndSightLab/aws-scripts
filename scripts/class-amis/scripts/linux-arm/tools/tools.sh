#!/bin/bash

function pipi(){
	pkg=$1
	echo '**** '$pkg' ****'
	python3 -m pip install $pkg --user || echo "installing $pkg failed"
}

function pipis(){
        pkg=$1
				echo '************************************'
				echo 'Pip Install '$pkg
				echo '************************************'
        sudo python3 -m pip install $pkg || echo "installing $pkg failed"
}

function pipu(){
        pkg=$1
        echo '************************************'
        echo 'Pip Update '$pkg
        echo '************************************'
        python3 -m pip install $pkg --upgrade --user || echo "upgrading $pkg failed"
}

function yumi(){
        pkg=$1
        echo '************************************'
        echo 'Yum Install '$pkg
        echo '************************************'
        sudo yum install -y $pkg || echo "installing $pkg failed"
}

pipu pip

sudo yum clean all
sudo yum update -y

sudo yum groupinstall "Development Tools"

yumi mlocate
echo '****run updatedb for mlocate****'
sudo updatedb

yumi wireshark
yumi tcpdump
yumi nmap
yumi autoconf
yumi automake
yumi libtool
yumi libffi
yumi libffi-devel
yumi libxml2
yumi libxml2-devel
yumi libxslt
yumi libxslt-devel
yumi yum-utils
yumi amazon-linux-extras
yumi golang
yumi gcc
yumi openssl-devel 
yumi bzip2-devel
yumi python3-devel

pipi cffi

#requires sudo
pipis boto3
pipis netaddr

#upgrade
pipu setuptools

pipi paramiko
pipi html
pipi argparse
pipi dnspython
pipi requests
pipi jsbeautifier
pipi pathlib
pipi bs4

pipi ansible
ansible --version
ansible-galaxy install git+https://github.com/anthcourtney/ansible-role-cis-amazon-linux.git

pipi pipenv
pipi apache-libcloud
pipi ansi2html
pipi detect-secrets
pipi pycrypto
pipi chardet==2.3.0

history -c
