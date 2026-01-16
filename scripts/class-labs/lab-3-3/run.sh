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

lambda1='lambdaSecretInCode'
lambda2='lambdaSecretInEnvVar'
lambda3='lambdaSecretsManagerSecret'

echo "What is your default secret?"
read secret

echo "What secret would you like to seed into Secrets Manager?"
read secretmanagersecret

echo $'\nCreating a lambda function '$lambda1' with the secret embedded in the code'
aws cloudformation create-stack --stack-name $lambda1 --template-body file://$lambda1.yaml --parameters ParameterKey=lambdaFunctionName,ParameterValue=$lambda1 --capabilities CAPABILITY_IAM

echo $'\nCreating a lambda function '$lambda2 'with a secret in the environment variable in CloudFormation'
aws cloudformation create-stack --stack-name $lambda2 --template-body file://$lambda2.yaml --parameters ParameterKey=lambdaFunctionName,ParameterValue=$lambda2 ParameterKey=EnviroSecret,ParameterValue=$secret --capabilities CAPABILITY_IAM

echo $'\nCreating a lambda function '$lambda3' that uses a NoEcho parameter in CloudFormation and a secret in SecretsManager'
SSM_KMS_KEY=$(aws kms describe-key --key-id alias/aws/ssm --query KeyMetadata.KeyId --output text)
aws cloudformation create-stack --stack-name $lambda3 --template-body file://$lambda3.yaml --parameters ParameterKey=lambdaFunctionName,ParameterValue=$lambda3 ParameterKey=SecretParameter,ParameterValue=$secretmanagersecret ParameterKey=KeyId,ParameterValue=$SSM_KMS_KEY --capabilities CAPABILITY_IAM

aws cloudformation wait stack-create-complete --stack-name $lambda1
aws cloudformation wait stack-create-complete --stack-name $lambda2
aws cloudformation wait stack-create-complete --stack-name $lambda3

output1=$(aws cloudformation describe-stacks --stack-name $lambda1 --query 'Stacks[0].Outputs[0].OutputValue' --output text)
output2=$(aws cloudformation describe-stacks --stack-name $lambda2 --query 'Stacks[0].Outputs[0].OutputValue' --output text)
output3=$(aws cloudformation describe-stacks --stack-name $lambda3 --query 'Stacks[0].Outputs[0].OutputValue' --output text)

echo -e $'\nUse these commands to run the lambda functions. See the lab document for more details.'

echo "curl -w '\n' -XPOST $output1"
echo "curl -w '\n' -XPOST $output2"
echo "curl -w '\n' -XPOST $output3"
