#!/bin/bash
###EVENTUALLY THIS WILL BE FULLY AUTOMATED...TO THE EXTENT POSSIBLE####
###FOR NOW RUNNING THIS SCRIPT ECHOS OUT THE COMMANDS TO RUN LOCALLY###

echo ""
echo ""
echo "This script will walk through creating everything to create a new class: "
echo "- gmail address."
echo "- Bitbucket repo."
echo "- New aws acct."
echo "- X Acct role."
echo "- AMI share in new acct."
echo "- Call portal."
echo "- TODO: Things to do to fully automate the setup in TODO comments below."
echo ""
echo "Known issues:"
echo "- Need to set up OU in master account and roles for class admins to run this script, create new account in the correct OU"
echo "- Lambda function in CloudFront not fully automated."
echo "- Domain names are hokey - maybe just create a separate domain in the class OU so can fully automate the NS records somehow."k 
echo "- Domains take a while to propogate so after everything else have to wait for DNS - so this needs to be done ASAP before class!"
echo "- Publishing files to S3 bucket for registration portal - need to copy the initial files and transform them for the current class with proper domains. That may have been the purpose of the publish-initial.sh script, I forget."
echo "- Google automation to create new email account, drive, etc. is not done."
echo "- Bitbucket automation not done. I think they have some new functionality."
echo "- AMIs created in account, shared, not 100% automated"
echo "- Want a class registration e-commerce site. Ability to push out classes and waiting lists in diff locations. When enough people request to be on the waiting list, open up the class for registration."
echo "- Need to store class registrations (payment) with class registration code."
echo "- Automate creation of class infrasturcture with class registration code fully and then push all students into the registration database for the portal autoatically - same login they used to register for class"
echo "- Need admin portal: When a class starts, push a button to share everything each day of class for that day. I'm thinking the admin portal will be diff for every class to prevent one getting hacked for all. Will pull from the reg database on creation."
echo "- Logs and monitoring on eveerything"
echo "- CIS benchmarks and best practices on everything."
echo ""
echo "Ready to proceed?"
read yn
echo ""
#CLASS CODE
echo ""
echo "Decide on a class code."
echo "enter class code:"
read code

##USERNAME W MFA THAT WILL RUN SCRIPT TO SET UP CLASS
echo ""
echo "Enter an existing AWS user name with MFA turned on that run the scripts to set up the new class environment: "
read username

#ACCOUNT USER EXISTS IN
echo ""
echo "enter the account in which the user is created (default 751499613737): "
read mfaacct

###DEFINE VARIABLES###
awsprofile=$code
registrationregion=us-east-1
labregion=us-west-2

####CLASS EMAIL ALIAS#####
echo ""
email=$code"@2ndsightlab.com"
echo "create this email aws acct and google drive: " + $email
echo "Login to the account and turn on 2FA"
echo "TODO: Automate this with Google APIs"
echo ""
echo "Done?"
read yn

####CREATE ACCOUNT####
echo ""
echo "create new aws acct with this command"
echo "TODO: add to org"
echo "aws organizations create-account --email "$email" --account-name 2sl-"$code
echo ""
echo "Done?"
read yn

#### CONFIGURE NEW ACCT###
echo ""
echo "Login to master account to verify account was created"
echo "Login to the email account to verify received the email"
echo "Go to incognito window, then aws.amazon.com"
echo "Choose login, enter "$email" then click reset password"
echo "Click link in email to reset password"
echo "Done?"
read yn
echo ""
#### ENTER NEW ACCT # FOR SCRIPT ###
echo "TODO: Get new acct number from output or orgs via cli for this"
echo "Enter new class aws account (seattle: 703809947780)"
read newacct

####CREATE XACCT ADMIN ROLE####
echo ""
echo "TODO: Automate xacct role creation - manual for now"
echo ""
echo "In incognito browser login in new AWS acct, and create new role"
echo "go to cloudformation, choose create new stack"
echo "https://github.com/2ndSightLab/Cloud-Accounts/blob/master/iam-role-xdamin"
echo ""
echo "TODO: NOT working...update and fix this. Copy cisco config. Add automation in this class setup repo"
echo ""
echo "TODO: Need to set up OU for creating accounts under 2SL with permissions limited to that OU"
echo ""
echo "Done?"
read yn

#####ADD NEW ACCOUNT TO CLASS ADMIN GROUP POLICY####
echo "Add the account to the policy in the account where the user exists:"
echo "arn:aws:iam::$newacct:role/xadmin"
echo ""
echo "Currently this group + policy is in root org - need to move to the OU fo rclass admins and class accounts"
echo ""
echo "Done?"
read yn

###SET ACCOUNT ALIAS###
echo ""
echo "Change the account alias on the iam dashboard to 2sl-"$code
echo "return to master account and test switching roles (may take a minute for policy to propogate"
echo "TODO: Automate"
echo ""
echo "Done?"
read yn

####CREATE XACCT READ ONLY / SUPPORT ROLE####
echo "TODO: create read only support role for anyone that needs to log in and asssits with a problem"
echo ""

####CREATE CLI PROFILE ON LOCAL MACHINE####
echo ""
echo "type this to get into config file: vi ~/.aws/config"
echo "add this role profile (only need mfa if a condition of the xadmin policy):"
echo ""
echo "[profile "$code"]"
echo "role_arn = arn:aws:iam::$newacct:role/xadmin"
echo "source_profile = default"
echo "mfa_serial = arn:aws:iam::$mfaacct:mfa/$username"
echo "region = "$registrationregion
echo "output = json"
echo "Done?"
read yn

echo ""
echo "test it out:"
echo "aws ec2 describe-instances --profile "$code
echo ""
echo "Done?"
read yn

####CREATE ALL THE REGISTRATION STUFF####
echo ""
echo "The following file generates commands to run manually to create registration componenets"
echo ""
echo "git clone the following file and execute, passing in the class code"
echo "make sure in us-east-1 for all"
echo "follow the steps - a few which have to be manual"
echo "https://github.com/2ndSightLab/2SL-Class-Registration/blob/master/cfn/gen-commands.sh"
echo ""
echo "Done?"
read yn

##### PUBLISH THE IN GOOGLE DRIVE ####
echo "TODO: Automate with Google APIS"
echo "Create new class drive with all the class contents"
echo ""
echo "Done?"
read yn

#### Create class repo ####
echo "TODO: Automate creation of bitbucket repo for the class using bitbucket APIS"
echo "Done?"
read yn

##### CREATE THE AMIS IN US-WEST-2 #####
echo ""
echo "Create AMIs with following commands in new acct"
echo "git clone https://github.com/2ndSightLab/aws-packer-pfsense.git"
echo "cd aws-packer-pfsense"
echo "PFSense bucket Upload name?"
echo "read BUCKET_NAME"
echo "chmod +x run.sh"
echo "chmod +x run-createami.sh"
echo "./run.sh -b $BUCKET_NAME -r us-west"
echo "Done?"
read yn
echo ""

echo "TODO: Kolby - I don't know what this means. Can we automate this next step?"
echo "You will need to come back and finalize the creation of the AMI once the snapshot is imported"
echo "Done?"
echo "yn"
echo ""
echo "cd .."
echo "git clone https://github.com/2ndSightLab/2SL-Class-AMI.git"
echo "docker build --no-cache -t 2ndsightlab/packer -f Dockerfile.ami ."
echo "docker run -v $HOME/.aws/:/root/.aws/ 2ndsightlab/packer"
echo "docker rm 2ndsightlab/packer"


##### CREATE THE AMI SHARE #####
echo "git clone https://github.com/2ndSightLab/2SL-Class-Publisher.git
echo "docker build --no-cache -t 2ndsightlab/serverless -f Dockerfile .
echo "docker run -v $HOME/.aws/:/root/.aws/ 2ndsightlab/serverless
echo "docker rm 2ndsightlab/serverless
echo "Done?"
read yn

echo ""
echo "TODO: Kolby - not sure what this means below. Can we just output the correct commands as is done in above steps?"
echo "The curl looks like this:"
echo "curl -X POST -H "x-api-key: APIKEY" -H "Content-Type: application/json" -d '{"account_id”:"ACCOUNTID"}' https://zreq17g747.execute-api.us-west-2.amazonaws.com/dev/ami/share"
echo ""
echo "Done?"
echo yn

echo "TODO: Kolby - Can we just grab the output specifically and automatically with a CLI command for any of the following steps to generate the correct command dynamically?"
echo "You should get a return value like this:
echo "{"ami_id":"ami-03e66174c295753ce","return_code":"200”}"
echo ""
echo "Done?"
echo yn

##### SETUP THE PENTEST INFRATRUCTURE IN US-WEST-2 #####
echo "TODO: CTF"

##### SETUP THE INCIDENT US-WEST-2 #####
echo "TODO: Incident"

### SETUP FUNCTION TO SHARE W STUDENTS ###
echo "TODO: Admin portal/functionality to share with students."
echo "Done?"
ready yn

### IMPROVE SECURITY
echo "TODO: CIS Benchmarks and security on all APIs/pages/sites/accounts/AMIs"
echo "TODO: WAF on API GW"
echo "TODO: All logs on by default and shared with 2SL security account/centralization"
echo "TODO: Pentest all AMIS/web pages/portal"
echo "TODO: Add CSP and all approproiate security to web pages"
