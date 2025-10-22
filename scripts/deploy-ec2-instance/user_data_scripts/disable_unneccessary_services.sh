#!/bin/bash -sh

#one of these services causes the /home directory to disappear when disabled

sudo systemctl stop amazon-ssm-agent
sudo systemctl disable amazon-ssm-agent
#mask it to prevent it from being started again
sudo systemctl mask amazon-ssm-agent

sudo systemctl stop gssproxy
sudo systemctl disable gssproxy

#superceded by cron -why running on Amazon Linux by default?
sudo systemctl stop atd
sudo systemctl disable atd
