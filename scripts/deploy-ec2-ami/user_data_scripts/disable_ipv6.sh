#!/bin/bash -e

# Detect OS and disable IPv6
if [ -f /etc/redhat-release ] || [ -f /etc/amazon-linux-release ]; then
    # RHEL/CentOS/Amazon Linux
    echo "net.ipv6.conf.all.disable_ipv6 = 1" >> /etc/sysctl.conf
    echo "net.ipv6.conf.default.disable_ipv6 = 1" >> /etc/sysctl.conf
    sysctl -p
elif [ -f /etc/debian_version ]; then
    # Debian/Ubuntu
    echo "net.ipv6.conf.all.disable_ipv6 = 1" >> /etc/sysctl.conf
    echo "net.ipv6.conf.default.disable_ipv6 = 1" >> /etc/sysctl.conf
    sysctl -p
elif [ -f /etc/SuSE-release ]; then
    # SUSE
    echo "net.ipv6.conf.all.disable_ipv6 = 1" >> /etc/sysctl.conf
    echo "net.ipv6.conf.default.disable_ipv6 = 1" >> /etc/sysctl.conf
    sysctl -p
else
    echo "Unsupported OS for IPv6 disable"
    exit 1
fi
