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

region=$1

if [ "$region" == "" ]; then
    echo "Region cannot be empty when retrieving S3 CIDRs in get_s3_ips.sh"
    exit
fi

#ugly script to get S3 cidr params. Want to re-write in a more readable programming language someday
#or get AWS to allow passing an array of strings and ports to create a list of network rules..
#or have an easy switch to add S3 cidrs to network lists for YUM updates...

#Note: In production setting you would want to monitor the 
#AWS IP ranges for changes and update the NACL rules if
#the CIDR blocks change.
s3ips=$(curl -s https://ip-ranges.amazonaws.com/ip-ranges.json | \
python -c "import sys, json; ips = json.load(sys.stdin)['prefixes']; s3ips = [k['ip_prefix'].encode('ascii') for k in ips if k['service'] == 'S3' and k['region'] == '$region']; s3params = ['ParameterKey=params3cidr' + str(idx) + ',ParameterValue=' + item for idx, item in enumerate(s3ips)]; print (s3params)")

if [ "$region" != "us-east-1" ]; then
    s3eastips=$(curl -s https://ip-ranges.amazonaws.com/ip-ranges.json | \
    python -c "import sys, json; ips = json.load(sys.stdin)['prefixes']; s3eastips = [k['ip_prefix'].encode('ascii') for k in ips if k['service'] == 'S3' and k['region'] == 'us-east-1']; s3eastparams = ['ParameterKey=params3eastcidr' + str(idx) + ',ParameterValue=' + item for idx, item in enumerate(s3eastips)]; print (s3eastparams)")
fi

s3ips="$s3ips $s3eastips"

echo $s3ips | sed -e 's/\[//g' -e 's/]//g' -e 's/, / /g' -e "s/'//g"