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
    yourip=$(curl -s https://whatismyip.akamai.com/)
    if [ "$yourip" == "" ]; then yourip=$(curl -s https://ifconfig.co/ip); fi
    if [ "yourip" != "" ]; then defaultadmincidr="$yourip/32";fi
    echo "0.0.0.0/0"
}

function get_latest_pfsense_ami(){
    owner="974236937774"
    imageid=$(aws ec2 describe-images --owners $owner --filters "Name=name,Values=2nd-Sight-Lab-pfsense-*" --query 'reverse(sort_by(Images,&CreationDate))[].[ImageId]' --output text | sed -n 1p) 
    echo $imageid
}

dt=$(date)
region=$(aws configure get region)
rm -f *.txt
echo "* ---- START PFSense SCRIPT ----------------------------"
echo "* $dt" 
echo "* ---- REGION ------------------------------------------"
echo "* Your CLI is configured for region: " $region
echo "* Resources will be created in this region."
echo "* Switch to this region in console when you login."
echo "* ------------------------------------------------------"

echo "Select action:"
select cudl in "Create/Update" "Delete" "Cancel"; do
    case $cudl in
        Create/Update ) action="create";break;;
        Delete ) action="delete";break;;
        Cancel ) exit;;
    esac
done

if [ "$action" == "delete" ]; then
    echo "Delete Non-Billable Resources (Y)?"
    read deleteall
    if [ "$deleteall" == "y" ]; then deleteall="Y"; fi
fi

if [ "$action" != "delete" ]; then

    defaultinstancetype="t2.micro"
    defaultpubliccidr="10.0.0.0/24"
    defaultwebcidr="10.0.1.0/24"
    
    yourip=$(curl -s ifconfig.me)
    echo "Enter the Admin IP range (example: $yourip/32)"
    read defaultadmincidr

    echo "* ------------------------------------------------------"
    echo "Retrieving PFSense AMI..."
    pfsenseami=$(get_latest_pfsense_ami)
    if [ "$pfsenseami" = "" ]; then 
        echo "No PFSense AMIs have been found. Please see README.md"; 
        exit; 
    fi

    echo "Default values:"
    echo "pfsense ami: $pfsenseami"
    echo "instance type: $defaultinstancetype"
    echo "public cidr: $defaultpubliccidr"
    echo "private cidr: $defaultwebcidr"

    echo "* ------------------------------------------------------"
    echo "* Would you like to use all the default options? (Y)"
    read usedefault
    if [ "$usedefault" == "y" ]; then usedefault="Y"; fi

    if [ "$usedefault" != "Y" ]; then

        echo "Enter PFSense AMI (default: $pfsenseami)"
        read ami

        echo "Instance Type (default: t2.micro- See README.md for requirements):"
        read instancetype

        echo "Public Subnet Cidr (default is 10.0.0.0/24):"
        read publiccidr

        echo "Private Server Subnet Cidr (default is 10.0.1.0/24):"
        read privateservercidr
    
    fi

    if [ "$ami" = "" ]; then ami="$pfsenseami"; fi
    if [ "$instancetype" = "" ]; then instancetype="$defaultinstancetype"; fi
    if [ "$publiccidr" = "" ]; then publiccidr="$defaultpubliccidr"; fi
    if [ "$privateservercidr" = "" ]; then privateservercidr="$defaultwebcidr"; fi
    if [ "$adminips" = "" ]; then adminips="$defaultadmincidr"; fi

    if [ "$action" = "" ]; then echo "action cannot be null"; exit; fi
    if [ "$adminips" = "" ]; then echo "adminips cannot be null"; exit; fi
    if [ "$ami" = "" ]; then echo "ami cannot be null"; exit; fi
    if [ "$instancetype" = "" ]; then echo "instancetype cannot be null"; exit; fi
    if [ "$publiccidr" = "" ]; then echo "publiccidr cannot be null"; exit; fi
    if [ "$privateservercidr" = "" ]; then echo "privateservercidr cannot be null"; exit; fi

fi

#get the user information to get an active session with MFA
user=$(aws sts  get-caller-identity --query 'Arn' | tr -d '"' | cut -d "/" -f2)

if [ "$user" = "" ]; then echo "adminuser cannot be null"; exit; fi

#if no errors create the stack
echo "Executing: $action with $user as admin user with ips: $adminips ami: $ami instancetype: $instancetype" 
echo "* ------------------------------------------------------"
echo "
. ./execute/action.sh $action $user $adminips $ami $instancetype $publiccidr $privateservercidr $deleteall"
. ./execute/action.sh $action $user $adminips $ami $instancetype $publiccidr $privateservercidr $deleteall

rm -f *.txt
dt=$(date)
echo "Done $dt"