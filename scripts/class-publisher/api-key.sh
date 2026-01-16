#!/usr/bin/env bash

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

APIID=$(aws apigateway get-rest-apis | jq '.items[] | select(.name == "ami-share-fxn").id' -r)
USAGEPLAN=$(aws apigateway create-usage-plan --name "ami-share" | jq '.id' -r)
APIKEY=$(aws apigateway create-api-key --name 'ami-share-key' --description 'ami-share-key' --enabled | jq '.id' -r)

aws apigateway create-usage-plan-key --usage-plan-id $USAGEPLAN --key-type "API_KEY" --key-id $APIKEY

aws apigateway update-usage-plan --usage-plan-id $USAGEPLAN --patch-operations "[{\"op\":\"add\",\"path\":\"/apiStages\",\"value\":\"${APIID}:Prod\"}]"