#!/bin/bash

vpcid=$(aws ec2 describe-vpcs --filters "Name=isDefault, Values=true" --query Vpcs[0].VpcId --output text)

subnetid=$(aws ec2 describe-subnets --filters "Name=vpc-id,Values=$vpcid" "Name=availability-zone,Values=us-west-2a" --query 'Subnets[0].SubnetId' --output text)

user=$(aws sts  get-caller-identity --query 'Arn' | tr -d '"' | cut -d "/" -f2)

export AWS_REGION="us-west-2"
export RUN_USER=$user
export VPC_ID=$vpcid
export SUBNET_ID=$subnetid

packer build ami/amazonlinux2.json

packer build ami/windows2016.json