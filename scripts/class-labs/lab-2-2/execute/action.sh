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

#note. I would prefer to be using a different language
# but this is how I started for non-programmers who
#are familiar with command line scripting.
action=$1
if [ "$action" == "delete" ]; then 
    adminuser=$2
    deleteall=$4
else    
    adminuser=$2
    admincidr=$3
    ami=$4
    instancetype=$5
    publiccidr=$6
    privateservercidr="${7}"
fi

keyname="pfsense-cli-ec2-key"

#stack = file name less the .yaml extension
function modify_stack(){
    local action=$1;
    declare -a stackarray=("${!2}")
    for (( i = 0 ; i < ${#stackarray[@]} ; i++ ))
    do
        run_template "$action" "${stackarray[$i]}"
    done
}

function run_template () {
    local action=$1; local stack=$2;local parameters="";
    
    echo "$action $stack"

    template="file://resources/$stack.yaml"
    stackname="pfsense-$stack"
    exists=$(stack_exists $stackname)
    parameters=$(get_parameters $stack)
    action=$(validate_action "$exists" "$action" "$stackname")

    if [ "$action" == "noupdates" ]; then echo "$action"; return; fi
    
    if [ "$action" == "fail" ]; then
        ./execute/run_template.sh "delete" "$stackname" "$parameters"
        wait_to_complete "delete" $stackname
        action="create"
    fi

    ./execute/run_template.sh "$action" "$stackname" "$template" "$parameters"
   
   if [ -f $stackname.txt ]; then
        noupdates="$(cat $stackname.txt | grep 'No updates')"
        if [ "$noupdates" != "" ]; then echo "noupdates to stack"; return; fi

        err="$(cat $stackname.txt | grep 'error\|failed\|Error')"
        if [ "$err" != "" ]; then echo "$err"; exit; fi
        
        cat $stackname.txt
        wait_to_complete $action $stackname
    else
        echo "Something is amiss. Stack output file does not exist: $stackname.txt"
        exit
    fi
}

function stack_exists(){
    local stackname=$1
    aws cloudformation describe-stacks --stack-name $stackname > $stackname.txt  2>&1  
    exists=$(./execute/get_value.sh $stackname.txt "StackId")
    echo "$exists"
}

function get_parameters(){
    stack=$1
    stackparameter="--parameters"

    if [ "$stack" == "network-vpc" ]; then
        echo "$stackparameter ParameterKey=Username,ParameterValue=$adminuser ";return
    fi

    if [ "$stack" == "network-nacls" ]; then
        echo "$stackparameter ParameterKey=ManagmentIPAddress,ParameterValue=$admincidr ";return
    fi

    if [ "$stack" == "pfsense-deployment" ]; then
        echo "$stackparameter ParameterKey=Username,ParameterValue=$adminuser ParameterKey=PFSenseAmiId,ParameterValue=$ami ParameterKey=PFSenseInstanceType,ParameterValue=$instancetype ParameterKey=PFSenseKeyName,ParameterValue=$keyname ParameterKey=ManagmentIPAddress,ParameterValue=$admincidr ";return
    fi

    echo "$stackparameter"
}

function get_ip_parameters(){
    name=$1;index=1;p=""
    ips=$(dig +short $name.watchguard.com | grep '^[1-9]')
    name=$(echo $name | sed -e 's/[.-]//g')
    for ip in $ips; do 
        p="$p ParameterKey=\"param$name$((index++))\",ParameterValue=\"$ip/32\""
    done
    echo $p
}

function validate_action(){
    local exists=$1;local action=$2;local stackname=$3;local config=$4;

    if [ "$action" == "delete" ]; then
        if [ "$exists" == "" ]; then action="noupdates"; fi
        echo $action
        return
    fi
    
    if [ "$exists" == "" ] && [ "$action" == "update" ]; then
        action="create"
    fi

    if [ "$exists" != "" ]; then 
        aws cloudformation describe-stacks --stack-name $stackname > $stackname.txt  2>&1  
        status=$(./execute/get_value.sh $stackname.txt "StackStatus")
        case "$status" in 
            ROLLBACK_COMPLETE|ROLLBACK_FAILED|DELETE_FAILED)
            action="fail"
            ;;
          *)
            action="update"
            ;;
          *)
        esac
    fi

    echo $action
}

function log_errors(){

    local stackname=$1;local action=$2

    aws cloudformation describe-stacks --stack-name $stackname > $stackname.txt  2>&1  
    exists=$(./execute/get_value.sh $stackname.txt "StackId")

    if [ "$exists" != "" ]; then

        aws cloudformation describe-stacks --stack-name $stackname > $stackname.txt  2>&1  
        status=$(./execute/get_value.sh $stackname.txt "StackStatus")
        echo "$stack status: $status"
        case "$status" in 
            UPDATE_COMPLETE|CREATE_COMPLETE)   
                if [ "$action" != "delete" ]; then
                    return
                fi
                ;;
            *)
        esac

        cat $stackname.txt
        aws cloudformation describe-stack-events --stack-name $stackname | grep "ResourceStatusReason"
        echo "* ---- What's the problem? ---"
        echo "* Stack $action failed."
        echo "* See the details above which can also be found in the CloudFormation console"
        echo "* ----------------------------"
        exit
        
    fi
}

function wait_to_complete () {
    local action=$1; local stack=$2
    ./execute/wait.sh $action $stack  
    log_errors $stack $action
}

#---Start of Script---#
if [ "$action" == "delete" ]; then

    echo "delete resources"
   
    echo "deleting all resources..."

    stack=(

        "pfsense-deployment"
        "network-nacls"
        "network-vpc" 

    )

    modify_stack $action stack[@] 

    ./execute/keypair.sh $action $keyname

else #create/update

    ./execute/keypair.sh $action $keyname

    stack=(

        "network-vpc" 
        "network-nacls"
        "pfsense-deployment"
        
    )
    modify_stack $action stack[@] 
    
fi


