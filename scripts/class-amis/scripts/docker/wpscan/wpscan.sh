#!/bin/bash

#Path to docer file
p="/home/ec2-user/tools/scans/wpscan"

docker build -t 2sl/wpscan $p

history -c
