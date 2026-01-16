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


action=$1;keyname=$2

echo "$action key $keyname"

aws ec2 describe-key-pairs --key-name $keyname > ec2key.txt  2>&1  
noexist=$(cat ec2key.txt | grep "does not exist")

if [ "$noexist" == "" ]
then
    if [ "$action" == "delete" ]; then
        aws ec2 delete-key-pair --key-name $keyname
        rm -f $keyname.pem
    fi
else
    if [ "$action" == "create" ]; then

        echo ""
        echo "* ---- NOTE --------------------------------------------"
        echo "* Creating EC2 keypair: $keyname"
        echo "* Do NOT check in keys to public source control systems."
        echo "* Keys are passwords. Protect them!"
        echo "* This github repository excludes .pem and .PEM files in the .gitignore file"
        echo "* https://git-scm.com/docs/gitignore"
        echo "* ------------------------------------------------------"
        echo ""
        
        aws ec2 create-key-pair --key-name $keyname --query 'KeyMaterial' --output text > $keyname.pem
        chmod 600 $keyname.pem
    fi
fi

