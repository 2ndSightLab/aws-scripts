#!/bin/bash -e

# Update and upgrade system packages based on OS
if [ -f /etc/redhat-release ] || [ -f /etc/amazon-linux-release ]; then
    # RHEL/CentOS/Amazon Linux
    yum update -y
elif [ -f /etc/debian_version ]; then
    # Debian/Ubuntu
    apt-get update -y
    apt-get upgrade -y
elif [ -f /etc/SuSE-release ]; then
    # SUSE
    zypper refresh
    zypper update -y
else
    echo "Unsupported OS for package updates"
    exit 1
fi
