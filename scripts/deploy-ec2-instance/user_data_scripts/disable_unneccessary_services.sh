#!/bin/bash -sh

sudo systemctl stop amazon-ssm-agent
sudo systemctl disable amazon-ssm-agent
#mask it to prevent it from being started again
sudo systemctl mask amazon-ssm-agent

sudo systemctl stop gssproxy
sudo systemctl disable gssproxy

#superceded by cron -why running on Amazon Linux by default?
sudo systemctl stop atd
sudo systemctl disable atd

#nfs
sudo systemctl disable nfs-client.target
sudo systemctl mask nfs-client.target
