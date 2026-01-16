

#use this to generate the commands to execute to build the class portal.
#the class prefix is unique to each class
#
#
#Notes:
#https://aws.amazon.com/blogs/networking-and-content-delivery/authorizationedge-how-to-use-lambdaedge-and-json-web-tokens-to-enhance-web-application-security/
#https://github.com/aws-samples/authorization-lambda-at-edge
#consolidate logs: https://aws.amazon.com/blogs/networking-and-content-delivery/aggregating-lambdaedge-logs/
#
#
#I think there's a new lambda@edge cloudformation thing to set up the lambda@edge behavior
#have to set to VIEW REQUEST not Origin request otherwise it only triggers when the item is not cached!!
#turn this all into CF nested stacks
#create a mechanism to automatically create a bucket, populate it, and upload the cfs when the script is run
#

echo "These are the things you will forget or not done:"
echo "1. Manually create NS records.
echo "2. DO NOT CREATE CNAME ENTRIES. RUN COMMANDS. THEY GO IN THE NEW ACCOUNT."
echo "3. Remember to run the publish-initial.sh script at the end."
echo "4. Remember to verify the email and add entries for new domain name."
echo "5. Remember to request that the email be moved out of the sandbox."
echo ""
echo "Stuff done manually:"
echo "Congnito annoying things."
echo "SES email verification."
echo "Google stuff."
echo "NS records."
echo "Run each individual command."
echo "Create AMI - want to add publishing the AMI to this acct."
echo "Create class repo in bitbucket"
echo "Add users in bitbucket"
echo ""
echo "GOT ALL THAT?"
echo "DID YOU READ IT????"
read enter

echo "Enter classcode: "
read classcode
nameprefix="CLS-2SL3000-"$classcode
awsprofile=$classcode
#for test environment leave blank? double chekc that - registration buckets.
env=$classcode
eastregion="us-east-1"
stackregion="us-east-1"

authdomain=$classcode-auth.2ndsightlab.com
contentdomain=$classcode-cloud.2ndsightlab.com

echo "Create a new gmail account: $classcode@2ndsightlab.com"
echo "Set up Yubikey"
echo "Login"
read enter

echo "Get the creds for this from 2sl-prod SM and create a separate profile."
echo "aws configure --profile org"
echo "region uswest, use keys"
read enter

echo "Test the credentials by calling the list roots command."
echo "aws organizations list-roots --profile org"
echo ""
echo "Run the command to create the new account"
echo ""
echo "aws organizations create-account --email $classcode@2ndsightlab.com --account-name $classcode --profile org"
read enter

echo "So this whole thing is not working..."
echo "Add the new account number to the xadmin group in the root account."
echo "Add the xadmin role in the new acct. Asssign otto."
echo "create a role profile that uses this role to access the new account."
echo "[profile $classcode]"
echo "role_arn = arn:aws:iam::[new acct]:role/xadmin"
echo "source_profile = default"
echo "Region: us-east-1"
echo "the commands created will specify us-east-1 explicitly."
read

#The domains have to be in us-east-1 for whatever reason
echo "..........................................................."
echo "STEP 1: CREATE CONTENT DOMAIN"
echo "Copy this and run it in another terminal window:"
echo ""
echo "aws cloudformation create-stack "\
--stack-name $nameprefix"-route53-content-domain --parameters \
ParameterKey=ParamDomainName,ParameterValue='"$contentdomain"' \
ParameterKey=ParamContentOrAuth,ParameterValue='Content' \
ParameterKey=ParamClassCode,ParameterValue='"$classcode"' \
--template-body=file://cfn/registration-route53-domain.yaml \
--profile "$awsprofile" \
--region "$stackregion
echo ""
echo "Enter to continue"
read enter

echo "..........................................................."
echo "STEP 2: CREATE AUTH DOMAIN"
echo ""
echo "aws cloudformation create-stack "\
--stack-name $nameprefix"-route53-auth-domain --parameters \
ParameterKey=ParamDomainName,ParameterValue='"$authdomain"' \
ParameterKey=ParamContentOrAuth,ParameterValue='Auth' \
ParameterKey=ParamClassCode,ParameterValue='"$classcode"' \
--template-body=file://cfn/registration-route53-domain.yaml \
--profile "$awsprofile "\
--region "$stackregion""
echo ""
echo "Enter to continue"
read enter
echo ""
echo "..........................................................."
echo "STEP 3: CREATE BUCKETS"
echo ""
echo "WAIT FOR DOMAINS to create as this stack uses outputs from the domains"
echo ""
echo "aws cloudformation create-stack "\
--stack-name $nameprefix"-s3-buckets --parameters \
ParameterKey=ParamClassCode,ParameterValue='"$classcode"' \
--template-body=file://cfn/registration-buckets.yaml \
--profile "$awsprofile "\
--region "$stackregion""
echo ""
echo "Enter to continue"
read enter
echo ""

echo "..........................................................."
echo "STEP 4: CREATE CONTENT CERTIFICATE"
echo "aws cloudformation create-stack "\
--stack-name $nameprefix"-content-certificate --parameters \
ParameterKey=ParamClassCode,ParameterValue='"$classcode"' \
ParameterKey=ParamContentOrAuth,ParameterValue='"Content"' \
--template-body=file://cfn/registration-certificate.yaml \
--profile "$awsprofile" \
--region "$eastregion

echo ""
echo "Enter to continue"
read enter
echo ""

echo "..........................................................."
echo "STEP 5: CREATE AUTH CERTIFICATE"
echo ""
echo "aws cloudformation create-stack "\
--stack-name $nameprefix"-auth-certificate --parameters \
ParameterKey=ParamClassCode,ParameterValue='"$classcode"' \
ParameterKey=ParamContentOrAuth,ParameterValue='"Auth"' \
--template-body=file://cfn/registration-certificate.yaml \
--profile "$awsprofile" \
--region "$eastregion

echo ""
echo "Enter to continue"
read enter
echo ""


echo "..........................................................."
echo "STEP 6: CREATE DNS RECORDS IN 2SL HOSTED ZONE"
echo ""
echo "" THEN NS RECORDS GO IN THE 2SL ACCOUNT"
echo ""
echo "Get the NS records from the new class domains from - Will look like this:"
echo ""
echo "ns-1276.awsdns-31.org."
echo "ns-440.awsdns-55.com."
echo "ns-890.awsdns-47.net."
echo "ns-1543.awsdns-00.co.uk."
echo ""
echo "Create a new ns record in 2ndSightLab.com hosted zone for each domain.
echo ""
echo "Put the NS domains as shown above in the Value textbox and click create."
echo ""
echo "TODO: Create an API in the 2SL account to automate this"
echo "FOR NOW ADMINS WILL HAVE TO ASK TR TO DO THIS"
echo ""
echo "Enter to continue"
read enter
echo ""
echo "..........................................................."
echo "STEP 7. STOP!!!!!!!!!!!!"
echo "Read the next instructions to correctly enter the information to create the CNAMES in the correct place and in the correct format."
echo ""
echo "..........................................................."
echo "STEP 8. CERTIFICATE VALIDATION STACK - CONTENT"
echo ""
echo "Look at the events for the certicate create, get the cname and cname value and enter them below to create the validation CNAME on the SUBDOMAINS in the CLASS account."
echo ""
echo "Enter Content (cloud) DNS Record name (when known - like _xxxxxxxxxxxxxxxxxxxxxx.classcodehere-cloud.2ndsightlab.com.): "
read contentcname
echo "Enter the Content (cloud) CNAME value (when known - like _xxxxxxxxxxxxxxxxxxxxxxxxx.xxxxxxxx.acm-validation.aws.):"
read contentcnamevalue
echo ""
echo "aws cloudformation create-stack "\
--stack-name $nameprefix"-registration-route53-cert-val-content --parameters \
ParameterKey=CName,ParameterValue='"$contentcname"' \
ParameterKey=CNameValue,ParameterValue='"$contentcnamevalue"' \
ParameterKey=ParamClassCode,ParameterValue='"$classcode"' \
ParameterKey=ParamContentOrAuth,ParameterValue='"Content"' \
--template-body=file://cfn/registration-route53-cert-val.yaml \
--profile "$awsprofile" \
--region "$stackregion
echo ""
echo "Enter to continue"
read enter
echo ""
echo "..........................................................."
echo "STEP 9. CERTIFICATE VALIDATION STACK - AUTH"
echo ""
echo "Enter auth DNS Record name (when known - like _xxxxxxxxxxxxxxxxxxxxxxxxxx.classcodehere-auth.2ndsightlab.com.): "
read authcname
echo "Enter auth CNAME value (when known - like _xxxxxxxxxxxxxxxxxxxxx.xxxxxxxxxx.acm-validations.aws.):"
read authcnamevalue
echo ""
echo "aws cloudformation create-stack "\
--stack-name $nameprefix"-registration-route53-cert-val-auth --parameters \
ParameterKey=CName,ParameterValue='"$authcname"' \
ParameterKey=CNameValue,ParameterValue='"$authcnamevalue"' \
ParameterKey=ParamClassCode,ParameterValue='"$classcode"' \
ParameterKey=ParamContentOrAuth,ParameterValue='"Auth"' \
--template-body=file://cfn/registration-route53-cert-val.yaml \
--profile "$awsprofile" \
--region "$stackregion
echo ""
echo "Enter to continue"
read enter
echo ""
echo "..........................................................."
echo "STEP 10. COGNITO POOL"
echo ""
echo "aws cloudformation create-stack "\
--stack-name $nameprefix"-cognito --parameters \
ParameterKey=ClassCode,ParameterValue='"$classcode"' \
--template-body=file://cfn/registration-cognito-pool.yaml \
--profile "$awsprofile" \
--region "$stackregion --capabilities CAPABILITY_IAM --capabilities CAPABILITY_NAMED_IAM
echo ""
echo "Enter to continue"
read enter
echo ""
echo "..........................................................."
echo "STEP 11. Manual cognito steps:"
echo ""
echo "Go to the AWS SES Service."
echo "Add a new email $classcode@2ndsightlab.com and verify by clicking the link sent to the email account."
echo "Enter to continue"
read enter

echo "Add and verify the from domain (at the bottom of the email address settings)."
echo "Requires adding some DNS records. Maybe automate DNS part later."
echo ""
echo "Enter to continue"
read enter
echo ""
echo "Cognito - Message Customizations (Left menu):"
echo "Choose $classcode@2ndsightlab.com as the to/from email address."
echo ""
echo "Enter to continue"
read enter
echo ""
echo "Cognito - App client settings:"
echo ""
echo "- Check Cognito User Pool"
echo "- enter call back url: https://"$contentdomain"/auth.html"
echo "- enter signout url: https://"$contentdomain
echo "- Choose OAuth Flows: Authorization code grant, Implicit"
echo "- Choose Allowed OAuth Scopes: openid, aws.cognito.signin.user.admin"
echo "TODO: Automate https://docs.aws.amazon.com/cli/latest/reference/cognito-idp/create-user-pool-client.html"
echo "OR: https://docs.aws.amazon.com/cli/latest/reference/cognito-idp/update-user-pool-client.html"
echo "Create USER: https://docs.aws.amazon.com/cli/latest/reference/cognito-idp/admin-create-user.html"
echo ""
echo "Enter to continue"
read enter
echo ""
echo "COGNITO DOMAIN = AUTH DOMAIN"
echo "After certs are validated as explained above:"
echo "Choose "$authdomain" for the cognito domain"
echo "Choose the corresponding SSL cert."
echo ""
echo "Enter to continue"
read enter
echo ""
echo "..........................................................."
echo "STEP 12. SSM Parameters"
echo ""
echo "REQUIRES COGNITO POOL TO BE COMPLETE"
echo ""
echo "Note: Issue importing jwks as param so just add manually after- maybe later"
echo "NOTE: due to lack of time - manually set the login url"
echo ""
echo "aws cloudformation create-stack "\
--stack-name $nameprefix"-ssm --parameters \
ParameterKey=ParamClassCode,ParameterValue='"$classcode"' \
--template-body=file://cfn/registration-ssm-params.yaml \
--profile "$awsprofile" \
--region "$stackregion
echo ""
echo "Enter to continue"
read enter
echo ""
echo "..........................................................."
echo "STEP 13. UPDATE JWKS PARAMETER"
echo ""
echo " Update the jwks value as specified with what was put in the value for this parameter in SSM console"
echo ""
echo "Enter to continue"
read enter
echo ""
echo "..........................................................."
echo "STEP 14. LAMBDA ROLE"
echo ""
echo "NOT YET AUTOMATED - Create lamba role with trust policy shown here:"
echo ""
echo "aws cloudformation create-stack "\
--stack-name $nameprefix"-iam-role-lambda \
--template-body=file://cfn/registration-iam-role-lambda.yaml \
--profile "$awsprofile" \
--region "$stackregion " --capabilities CAPABILITY_NAMED_IAM"
read enter
echo ""
echo "............................"
echo "STEP 15. UPLOAD ZIP FILE TO LAMBDA BUCKET"
echo ""
echo "aws s3 cp lambda/auth.zip s3://"$classcode"-2sl-lambda --profile "$classcode
echo "Enter to continue"
read enter
echo ""
echo "..........................................................."
echo "STEP 16. LAMBDA"
echo ""
echo "aws cloudformation create-stack "\
--stack-name $nameprefix"-lambda --parameters \
ParameterKey=ClassCode,ParameterValue='"$classcode"' \
--template-body=file://cfn/registration-lambda.yaml \
--profile "$awsprofile" \
--region "$eastregion
echo ""
echo "Enter to continue"
read enter
echo ""
echo "..........................................................."
echo "STEP 17. CLOUDFRONT"
echo ""
echo "REQUIRES DOMAINS TO BE COMPLETE"
echo ""
echo "aws cloudformation create-stack "\
--stack-name $nameprefix"-cloudfront --parameters \
ParameterKey=ClassCode,ParameterValue='"$classcode"' \
--template-body=file://cfn/registration-cloudfront-content.yaml \
--profile "$awsprofile" \
--region "$stackregion
echo ""

echo "..........................................................."
echo "STEP 18. CREATE COGNITO ALIAS"
echo ""
echo "AFTER CLOUDFRONT COMPLETE ENTER THE VALUES BELOW:"
echo ""
echo "Enter COGNITO cloudfront domain (after setting the domains on cognito this will appear at the bottom like d314j3ehyozr0t.cloudfront.net)"
read congitocloudfrontdomain
echo ""
echo "Enter CONTENT cloudfront domain (on the cloudfront for content main page in console like d1m0u8ourbhsc.cloudfront.net)"
read contentcloudfrontdomain
echo ""
echo "aws cloudformation create-stack "\
--stack-name $nameprefix"-route53-aliases --parameters \
ParameterKey=CognitoCloudFrontDomain,ParameterValue='"$congitocloudfrontdomain"' \
ParameterKey=ContentCloudFrontDomain,ParameterValue='"$contentcloudfrontdomain"' \
ParameterKey=ClassCode,ParameterValue='"$classcode"' \
--template-body=file://cfn/registration-route53-alias.yaml \
--profile "$awsprofile" \
--region "$stackregion
echo ""
echo "Enter to continue"
read enter
echo ""
echo "LOGO"
echo ""
echo "Add the logo to the cognito pool now that the domain has been updated."
echo "Logo is in github repo."
echo ""
echo "Enter to continue"
read enter
echo ""
echo "..........................................................."
echo "STEP 19. PUBLISH CONTENT"
echo "Now go to ../publish-initial.sh and run those commands to publish the html pages"
echo ""
echo "It should create /html/html-[class code here] directory with all the content files"
echo "Those files get pushed to the correct S3 bucket and the cloudfront distribution is invalidated to show the new content"
echo ""
echo "TROUBLESHOOTING"
echo ""
echo "Verify the new subndomain has:"
echo " - A record"
echo " - NS record"
echo "- SOA record"
echo "- CNAME record"
echo "If any are missing check cloud formation stacks as there may have been an error."
echo ""
echo "Domains:"
echo "Make sure the NS records were added on 2ndsighlab.com (in a different acct)."
echo "Make sure the correct NS records were associated with the correct domain."
echo ""
echo "Cognito:"
echo "Double check all manual steps were completed correctly with no errors."
echo ""
echo "Error Message:"
echo "'An error was encountered with the requested page' and the url says the client does not exist..."
echo "Fix:"
echo "Go into cognito and click on App clients to get the client ID. In ALL the content pages under /html/html-[class code here]/ .. all the pages need to have the correct URL and app client id."
echo ""
echo "Error message:"
echo "Amazon SES account is in Sandbox. Verify Send-to email address or Amazon SES Account (Service: AWSCognitoIdentityProviderService; Status Code: 400; Error Code: CodeDeliveryFailureException; Request ID: 5b5832a3-2281-401d-a97d-5c6eaac591b4)"
echo "Manually request limit increase."
ehco ""
echo "*****REMEMBER THAT THE LOGS ARE IN S3 TO GET THE INPUT DATA FROM THE WEB FORM ****"
