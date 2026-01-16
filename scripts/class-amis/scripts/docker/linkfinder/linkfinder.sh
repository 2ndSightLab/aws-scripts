#!/bin/bash

#path to linkfinder Docker file directory
p='/home/ec2-user/tools/scans/LinkFinder'
chmod 700 $p/*
docker build -t 2sl/linkfinder $p
