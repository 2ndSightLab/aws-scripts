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

mfa=$1;tokencode=$2

#get an STS session using MFA for bucket policy that requires MFA to upload files
aws sts get-session-token --serial-number $mfa --token-code $tokencode > "session.txt" 2>&1 
error=$(cat session.txt | grep "error\|Invalid")

if [ "$error" != "" ]
then 
    echo $error 
    exit
fi

accesskey=$(./execute/get_value.sh "session.txt" "AccessKeyId")
secretkey=$(./execute/get_value.sh "session.txt" "SecretAccessKey")
sessiontoken=$(./execute/get_value.sh "session.txt" "SessionToken")

#Linux/Mac
export AWS_ACCESS_KEY=$accesskey
export AWS_SECRET_ACCESS_KEY=$secretkey
export AWS_SESSION_TOKEN=$sessiontoken

#these commands will work on Windows or just use bash:
#https://msdn.microsoft.com/en-us/commandline/wsl/install_guide
#set AWS_ACCESS_KEY=$accesskey
#set AWS_SECRET_ACCESS_KEY=$secretkey
#set AWS_SESSION_TOKEN=$sessiontoken