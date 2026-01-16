#!/bin/bash
#echo "install gh later if need it. Make sure it runs after mkdirs"
cd /home/ec2-user/tools/downloads
wget https://github.com/cli/cli/releases/download/v2.1.0/gh_2.1.0_linux_armv6.tar.gz
tar -xf gh_2.1.0_linux_armv6.tar.gz
cd gh_2.1.0_linux_armv6/bin
cp gh /home/ec2-user/.local/bin
