#!/bin/bash
echo '************************************'
echo 'Make directories'
echo '************************************'


p=/home/ec2-user
d=$p'/tools'
if [ -d $d ]; then
	echo $d' already exists'
	exit
fi

cd $p
mkdir tools
cd tools
mkdir 2sl
mkdir downloads
mkdir scans
mkdir exploits
mkdir dfir
mkdir ops
mkdir venv
mkdir lists
mkdir tunnels
mkdir practice

history -c

