#!/bin/sh
#Create 2SL AMI
#################################
# Then most annoying things happened while creating this script:
# When I stored JSON in AWS parameter store it quoted all the variables \"whatever\"
# When I retrieved and tried to use those variables they didn't show in the terinal,
# and yet, they caused aws ssm get-parameter to fail because of the hidden ".
# Paramater store caused it's own demise.
# The other thing was, you have to put quotes around a dynamic value
# passed to a bash function sometimes or only the first letter gets passed.
# In other cases, the quotes around the variable causes errors as noted above.
# jq attribute names when trying to retrieve a value caused issues.
# When you use jq and the name of the value you are trying to retrieve has anything
# weird in it you have to put quotes around it. However, all variations of quotes
# with dynamic variables passed to a function to try to retrieve a value failed.
# I ended up using the jq arg function to define an argument used by the parsed value
# and had to REMOVE the quotes around the dymanic value passed to the bash function.
# What is this madness????
# Additionally, if you don't have packer installed and run packer on this arm
# AWS Linux instance, it doesn't tell you the command is not found. It just hangs.
# What is that???
# At one point I forgot that I had retrieved the AWS SSM parameter but I was
# trying to parse my json value that I stored. I forgot that I had not
# pulled that sub-value out before trying to parse it. Eventually I figured
# this out by printing out the string I was trying to parse.
# Someone yelled at me after I had this all working the first time and I accidentally 
# shut down my AMI and didn't check my code in. TERMINATION PROTECTION!!! ARGGGH!!!
# Hours of work down the tubes but oh well the re-write is better.
# The next day I saw these weird files generated and not sure why. The names started
# with build, which also happens to be what the name of this files starts with.
# Guess what. rm build.* was not a good idea. I had partially checked in the code
# at this point but had to do a bunch of stuff over again...
# Do not do what I do. Be careful. Bash quotes kind of stink.
# Spent way too much time on this and writing it down to try to remember.
#
# OMG OMG spent way too long on this: the volume name you add to an ami cannot 
# overlap with the root volume name and fricking AWS doesn't block from doing that.
# UGGGGHHHH. Way too much time.
#
# OK There's some weird issue encrypting the boot volume.
# first there's a separate encrypt_boot option apparently instead
# of using KMS key???
#
# Secondly distinction between launch_block_device_mappings and ami_block_device_mappings
# Not clear what is going on. I guess the lauch option is if you need the drives available
# for packer.
#################################

#functions to get values from parameter store and json
function get_ssm_param(){ echo $(aws ssm get-parameter --name $1 --with-decryption); }
function get_ssm_param_value(){ echo $(jq -r .Parameter.Value <<< $1); }
function add_packer_var(){ vars=$vars'-var '$1' '; }
#note: have to remove the double quotes
function get_jq_val(){ echo $(jq --arg e "${1}" '.ami[$e]' <<< $2 | sed 's/"//g'); }

echo "Assume Packer Role"
#To get out of packer role unset credentials
#unset AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY AWS_SESSION_TOKEN
echo "------------------------------------------------"
assumerole="arn:aws:iam::453844007816:role/2sl-packer-role"
profile="AmiBuilder"
serial="arn:aws:iam::464339214996:mfa/app"
echo "Enter MFA Token:"
read token
#echo "aws sts assume-role --serial-number $serial --token-code $token --role-arn $assumerole  --role-session-name 2SLPACKERSESSION --profile $profile"
assumerolejson=$(aws sts assume-role --serial-number $serial --token-code $token --role-arn $assumerole  --role-session-name 2SLPACKERSESSION --profile $profile)
#echo $assumerolejson; echo "Assume role ok?"; read ok

echo "Set env var credentials and check identity"
echo "------------------------------------------------"
id=$(echo $assumerolejson | jq .Credentials.AccessKeyId | sed 's/"//g')
key=$(echo $assumerolejson | jq .Credentials.SecretAccessKey | sed 's/"//g')
session=$(echo $assumerolejson | jq .Credentials.SessionToken | sed 's/"//g')
#echo $id; echo $key; echo $session; echo "Values ok?"; read ok

export AWS_ACCESS_KEY_ID=$id
export AWS_SECRET_ACCESS_KEY=$key
export AWS_SESSION_TOKEN=$session
export AWS_REGION=us-east-2

aws sts get-caller-identity
echo "Idenity ok?"; read ok

echo "Check packer install"
echo "------------------------------------------------"
packer --version
#echo "packer ok?"; read ok

#software version config update
ok="" 
#echo "Do you want to update all the software and ami version parameters? (y)"; read ok
if [ "$ok" == "y" ]; then
  echo "running scripts/init/init-params.sh"
	scripts/init/init-params.sh
	echo "Parameters updated"
fi

ok=""
#software in s3 bucket update
#echo "Do you want to update all software in the S3 repo? (y)"; read ok
if [ "$ok" == "y" ]; then
	echo "Running scripts/init/init-2sl-repo.sh"
  scripts/init/init-2sl-repo.sh
	echo "Running scripts/init/init-repo.sh"
	scripts/init/init-repo.sh
	echo "Code in s3 updated"
else
	echo "No software updated"
fi
echo ""

echo "Choose an ami type:"
echo "------------------------------------------------"
echo "1 - Linux Base arm"
echo "2 - Linux Tools arm (S3 repo, base tools and libraries)"
echo "3 - Linux Pentest arm (Install and configure pentest tools)"
echo "4 - Linux Builder arm (Everything + github sync script)"
echo "5 - Windows Base (Base Windows AMI)"
echo "6 - Windows Pentest (2SL Pentest Configuration)"
read ami_type

case $ami_type in
1)
 		ami_name='ami.linux.arm.base' ;;
2)
		ami_name='ami.linux.arm.tools' ;;
3)
    ami_name='ami.linux.arm.pentest' ;;
4)
	  ami_name='ami.linux.arm.builder' ;;
5)
    ami_name='ami.windows.base' ;;
6)
    ami_name='ami.windows.pentest' ;;
*)
   echo "Invalid choice. Choose one of the options listed"; exit

esac

ssm_ami_config=$ami_name".config"
ssm_ami_latest=$ami_name".latest"

#GLOBAL -- PACKER VARS
#       "ami-builder-region" : "",
#       "ami-builder-vpc-id" : "",
#       "ami-builder-subnet-id" : "",
#       "iam-profile" : "",
#       "kms-key-id" : "",

#AMI - PACKER VARS
#      "ami" : "",
#      "ami-type" : "",
#      "ami-name" : "",
#      "ami-description" : "",
#      "volume-size" : "16",
#      "instance-type" : ""

#AMI - OTHER
#      template
#      ss_param_base_ami

ssm_global_config="ami.builder.global.params"

#echo "get global config from ss param: "$ssm_global_config
#echo "------------------------------------------------"
c=$(get_ssm_param $ssm_global_config)
c=$(get_ssm_param_value "$c")
#echo $c; echo "Ok?"; read ok

params=( \
       'ami-builder-region'
       'ami-builder-vpc-id'
       'ami-builder-subnet-id'
			 'iam-profile'
       'kms-key-id'
)

echo "------------------------------------------------"
echo "add packer vars from "$ssm_global_config
for p in ${params[@]}; do
	v=$(echo $c | jq --arg k "$p" '.[$k]')
  v=$(echo $v | sed 's/"//g')
	add_packer_var $p"="$v
done

echo "------------------------------------------------"
echo "get ami config from ss param: "$ssm_ami_config

params=( \
       'ami-description'
       'volume-size'
       'instance-type'
)

c=$(get_ssm_param $ssm_ami_config)
c=$(get_ssm_param_value "$c")

echo "------------------------------------------------"
echo "add packer vars from "$ssm_ami_config
#echo $c; echo "OK?"; read ok
for p in ${params[@]}; do
	echo "get vaue: "$p
  v=$(echo $c | jq --arg k "$p" '.[$k]')
  v=$(echo $v | sed 's/"//g')
  add_packer_var $p"="$v
done

#echo $vars; echo "packer vars ok?"; read ok
 
#echo "get the packer template"
#echo "------------------------------------------------"
template=$(echo $c | jq '.template')
template=$(echo $template | sed 's/"//g')
#echo "Template ok? "$template; read ok

#echo "get the ssm parameter that holds the base ami id on which this ami is built"
#echo "------------------------------------------------"
k=$(echo $c | jq '.ssm_param_base_ami')
k=$(echo $k | sed 's/"//g')
#echo "AMI SSM Param ok? '"$k"'"; read ok
echo "get the value of the ssm parameter that holds the base ami id on which this ami is built"
echo "------------------------------------------------"
p=$(get_ssm_param $k)
#echo $p; echo "Param output ok?"
ami=$(get_ssm_param_value "$p")
add_packer_var 'ami='$ami

#echo "create ami version name"
#echo "------------------------------------------------"
read Y M D <<<$(date +'%Y %m %d')
read H MM AMPM TZ <<<$(date +'%H %M %p %Z')
ami_version_name=$ami_name'-'$Y$M$D'-'$H$MM$AMPM$TZ 
add_packer_var 'ami-name='$ami_version_name

echo "run packer"
echo "------------------------------------------------"
export PACKER_LOG=1
export PACKER_LOG_PATH='/home/ec2-user/packer/'$ami-name'-packerlog.txt'
cmd='packer build '$vars' packer/'$template
echo ""; eval ' $cmd'; echo ""

echo "get new ami id for "$ami_version_name"?"; read ok
image_id=$(aws ec2 describe-images --owners 453844007816 --filters Name="name",Values=$ami_version_name --query 'Images[*].[ImageId]' --output text)

echo "Get latest ami from ssm param: "$ssm_ami_latest
p=$(get_ssm_param "$ssm_ami_latest")
oamid=$(get_ssm_param_value "$p")

echo "save image id: $image_id?"; read ok
#note, this key is different than the one used to encrypt amis!
kmskey='arn:aws:kms:us-east-2:639060417242:key/0e6a08d2-164b-487c-9c2f-ae4ec2940cbd'
aws ssm put-parameter --name $ssm_ami_latest --value $image_id --type SecureString --key-id $kmskey --overwrite

echo "Deregister old ami: $oamid?"; read ok
aws ec2 deregister-image --image-id $oamid

#if checkin
echo "checkin? Enter comments:"; read c
git add .; git commit -m "ami-build: $ami_name $c"; git push

