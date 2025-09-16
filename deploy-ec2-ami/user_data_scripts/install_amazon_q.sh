#!/bin/bash

# Detect OS
if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS=$ID
    VERSION=$VERSION_ID
else
    echo "Cannot detect OS"
    exit 1
fi

# Install Amazon Q based on OS
case $OS in
    "ubuntu")
        apt-get update
        curl -sSL https://aws-dev-tools-downloads.s3.us-east-1.amazonaws.com/amazon-q/latest/linux/amd64/amazon-q-linux-amd64.tar.gz -o /tmp/amazon-q.tar.gz
        tar -xzf /tmp/amazon-q.tar.gz -C /tmp/
        mv /tmp/q /usr/local/bin/
        chmod +x /usr/local/bin/q
        ;;
    "amzn"|"rhel"|"centos")
        yum update -y
        curl -sSL https://aws-dev-tools-downloads.s3.us-east-1.amazonaws.com/amazon-q/latest/linux/amd64/amazon-q-linux-amd64.tar.gz -o /tmp/amazon-q.tar.gz
        tar -xzf /tmp/amazon-q.tar.gz -C /tmp/
        mv /tmp/q /usr/local/bin/
        chmod +x /usr/local/bin/q
        ;;
    *)
        echo "Unsupported OS: $OS"
        exit 1
        ;;
esac

# Verify installation
/usr/local/bin/q --version
