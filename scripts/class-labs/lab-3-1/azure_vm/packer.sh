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

read -p 'App id:' client_id
read -p 'Password:' password
read -p 'Tenant:' tenant_id
read -p 'Subscription id:' subscription_id

username=$(aws iam get-user --query 'User.UserName')
resource_group='2SL3000'
azure_region='westus2'

packer build \
-var 'azure_client_id='$client_id \
-var 'azure_client_secret='$password \
-var 'azure_tenant_id='$tenant_id \
-var 'azure_subscription_id='$subscription_id \
-var 'azure_region='$azure_region \
-var 'run_user='$username \
-var 'resource_group='$resource_group \
azure.json
