#!/bin/sh
#####################################################################################################
# Copyright Notice
# All Rights Reserved.
# All course materials (the “Materials”) are protected by copyright under U.S. Copyright laws 
# and are the property of 2nd Sight Lab. They are provided pursuant to a royalty free, 
# perpetual license to the course attendee (the "Attendee") to whom they were presented by 
# 2nd Sight Lab and are solely for the training and education of the Attendee. The Materials 
# may not be copied, reproduced, distributed, offered for sale, published, displayed, performed, 
# modified, used to create derivative works, transmitted to others, or used or exploited in any way, 
# including, in whole or in part, as training materials by or for any third party.

# The above copyright notice and this permission notice shall be included in all copies or 
# substantial portions of the Software.

# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING 
# BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND 
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES 
# OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN 
# CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
#####################################################################################################

function get_default_admin_cidr(){
    #yourip=$(curl -s https://whatismyip.akamai.com/)
    #if [ "$yourip" == "" ]; then yourip=$(curl -s https://ifconfig.co/ip); fi
    #if [ "yourip" != "" ]; then defaultadmincidr="$yourip/32";fi
    #echo "$defaultadmincidr"
    echo "0.0.0.0/0"
}

function get_username(){
    user=$(aws sts  get-caller-identity --query 'Arn' | tr -d '"' | cut -d "/" -f2)
    echo "$user"
}


echo "Select action:"
select cudl in "CreateJenkins" "DeleteJenkins" "CreateClair" "DeleteClair" "Cancel"; do
    case $cudl in
        CreateJenkins ) action="create";break;;
        DeleteJenkins ) action="delete";break;;
        CreateClair ) action="createclair";break;;
        DeleteClair ) action="deleteclair";break;;
        Cancel ) exit;;
    esac
done

keyname="cls-2sl3000-jenkins-key"

if [ "$action" == "createclair" ]; then
  #set the vpcid to the default vpc
    vpcid=$(aws ec2 describe-vpcs --filters "Name=isDefault, Values=true" --query Vpcs[0].VpcId)

    #set the subnet id to any default subnet
    subnetid=$(aws ec2 describe-subnets --filters "Name=vpc-id,Values=$vpcid" "Name=availability-zone,Values=us-west-2a" --query 'Subnets[0].SubnetId')

    if [ "$vpcid" = "" ]; then echo "vpc id cannot be null"; exit; fi
    if [ "$subnetid" = "" ]; then echo "subnet id cannot be null"; exit; fi

    ignore1=$(rm -f $keyname-clair.pem ) #nothing to do
    ignore2=$(aws ec2 delete-key-pair --key-name $keyname-clair ) #nothing to do

    aws ec2 create-key-pair --key-name $keyname-clair --query 'KeyMaterial' --output text > $keyname-clair.pem
    chmod 600 $keyname-clair.pem

    adminIP=$(get_default_admin_cidr)
    user=$(get_username)

    echo "Creating stack"

    cloudformationReturn=$(aws cloudformation create-stack --stack-name cls-2sl3000-jenkins-clair --template-body file://clair-cloudformation.yaml --parameters ParameterKey=KeyName,ParameterValue=${keyname}-clair ParameterKey=VpcId,ParameterValue=${vpcid} ParameterKey=Subnet,ParameterValue=${subnetid} ParameterKey=Username,ParameterValue=${user} ParameterKey=ManagmentIPAddress,ParameterValue=${adminIP} --capabilities CAPABILITY_NAMED_IAM)

    echo "Waiting for stack to finish creating"

    stackwait=$(aws cloudformation wait stack-create-complete --stack-name cls-2sl3000-jenkins-clair)

    clairIP=$(aws cloudformation describe-stacks --stack-name cls-2sl3000-jenkins-clair --query 'Stacks[0].Outputs[0].OutputValue' --output text)
    echo "IP Address to use for Clair in Jenkins: ${clairIP}."
    exit
fi


if [ "$action" == "create" ]; then
    #echo "Enter deployment VPC ID"
    #read vpcid

    #echo "Enter deployment subnet ID"
    #read subnetid

    #set the vpcid to the default vpc
    vpcid=$(aws ec2 describe-vpcs --filters "Name=isDefault, Values=true" --query Vpcs[0].VpcId)

    #set the subnet id to any default subnet
    subnetid=$(aws ec2 describe-subnets --filters "Name=vpc-id,Values=$vpcid" "Name=availability-zone,Values=us-west-2a" --query 'Subnets[0].SubnetId')

    if [ "$vpcid" = "" ]; then echo "vpc id cannot be null"; exit; fi
    if [ "$subnetid" = "" ]; then echo "subnet id cannot be null"; exit; fi

    ignore1=$(rm -f $keyname.pem ) #nothing to do
    ignore2=$(aws ec2 delete-key-pair --key-name $keyname ) #nothing to do

    aws ec2 create-key-pair --key-name $keyname --query 'KeyMaterial' --output text > $keyname.pem
    chmod 600 $keyname.pem

    adminIP=$(get_default_admin_cidr)
    user=$(get_username)

    echo "Creating stack"

    cloudformationReturn=$(aws cloudformation create-stack --stack-name cls-2sl3000-jenkins --template-body file://jenkins-cloudformation.yaml --parameters ParameterKey=KeyName,ParameterValue=${keyname} ParameterKey=VpcId,ParameterValue=${vpcid} ParameterKey=Subnet,ParameterValue=${subnetid} ParameterKey=Username,ParameterValue=${user} ParameterKey=ManagmentIPAddress,ParameterValue=${adminIP} --capabilities CAPABILITY_NAMED_IAM)

    echo "Waiting for stack to finish creating"

    stackwait=$(aws cloudformation wait stack-create-complete --stack-name cls-2sl3000-jenkins)

    jenkinsIP=$(aws cloudformation describe-stacks --stack-name cls-2sl3000-jenkins --query 'Stacks[0].Outputs[0].OutputValue' --output text)
    echo "Connect to Jenkins at: http://${jenkinsIP}."
    exit
fi

if [ "$action" == "delete" ]; then

    echo "Cleaning up keypair"
    aws ec2 delete-key-pair --key-name $keyname
    rm -f $keyname.pem

    echo "Delete cloudformation statck"
    cloudformationReturn=$(aws cloudformation delete-stack --stack-name cls-2sl3000-jenkins)

    echo "Waiting for cleanup to complete"
    stackwait=$(aws cloudformation wait stack-delete-complete --stack-name cls-2sl3000-jenkins)
    
    echo "Cloudformation template cleaned up."
    exit
fi

if [ "$action" == "deleteclair" ]; then
    echo "Cleaning up keypair"
    aws ec2 delete-key-pair --key-name $keyname-clair
    rm -f $keyname-clair.pem

    echo "Delete cloudformation statck"
    cloudformationReturn=$(aws cloudformation delete-stack --stack-name cls-2sl3000-jenkins-clair)

    echo "Waiting for cleanup to complete"
    stackwait=$(aws cloudformation wait stack-delete-complete --stack-name cls-2sl3000-jenkins-clair)
    
    echo "Cloudformation template cleaned up."
    exit
fi

echo "There was an error"
exit