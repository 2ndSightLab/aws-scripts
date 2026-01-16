#!/bin/sh
#path to docker file dir
p="/home/ec2-user/tools/scans/nikto"
docker build -t 2sl/nikto $p
