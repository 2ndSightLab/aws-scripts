
#use this to generate the commans to execute
#the class prefix is unique to each class
echo "Enter classcode: "
read classcode
echo ""

if [ "" == $classcode ]; then
	echo "Not a valid classcode"
	exit
fi

echo "Enter shared labs link: "
read lablink
lablink=$(echo $lablink | sed 's/\//\\\//g')

echo ""
echo "Enter shared slides link: "
read slidelink
slidelink=$(echo $slidelink | sed 's/\//\\\//g')
echo ""
echo "Enter link to setup document: "
read startupdoclink
startupdoclink=$(echo $startupdoclink | sed 's/\//\\\//g')
echo $startupdoclink

echo ""
echo "Enter class repository name:"
read repo

#echo "Enter cognito region: "
#read region
region=us-east-1
cognitopoolname="2sl-ClassRegistration-"$classcode
echo ""

cmd="aws cognito-idp list-user-pools --max-results 20 --profile $classcode --query 'UserPools[?Name==\`2sl-ClassRegistration-"$classcode"\`]'.Id --output text --region $region"
echo $cmd
echo ""
result="`eval ${cmd}`"
poolid=$(echo "$result")

if [ "" == $poolid ]; then
	echo "No pool id found"
	exit
fi

cmd="aws cognito-idp list-user-pool-clients --user-pool-id $poolid --max-results 20 --profile $classcode  --query 'UserPoolClients[?ClientName==\`2SL-client-"$classcode"\`]'.ClientId --output text --region us-east-1"
#cmd="aws cognito-idp list-user-pool-clients --user-pool-id $poolid --max-results 20 --profile $classcode  --region us-east-1"

echo $cmd
echo ""
result="`eval ${cmd}`"
clientid=$(echo "$result")

if [ "" == $clientid ]; then
	echo "No client id found"
	exit
fi

if [ $classcode == 'cloudy' ]; then
	domain=$classcode".2ndsightlab.com"
else
	domain=$classcode"-cloud.2ndsightlab.com"
fi

cmd="aws cloudfront list-distributions --profile $classcode --query 'DistributionList.Items[?contains(Aliases.Items,\`$domain\`)].Id'"
result="`eval ${cmd}`"

distributionid=$(echo "$result")
distroid=$(echo $distributionid | sed 's/\[ "//' | sed 's/\" ]//')

if [ "null" == $distroid ]; then
        echo "No cloudfront distribution id found"
        exit
fi

echo "domain: " $domain
echo "cognito poolid: " $poolid
echo "cognito app client id: "$clientid
echo "cloudfront distribution id "$distroid
echo "Bitbucketrepo: $repo

echo "Looks ok?"
read return

#sdu=$(echo $setupdocurl | sed 's/\//\\\//g')
#echo $sdu

#make a folder for the files and copy the base files to the new folder"
echo ""
cmd='rm -rf html/html-"$classcode";mkdir html/html-"$classcode"'
echo $cmd
eval $cmd
cmd="ls -al html"
echo $cmd
eval $cmd
echo "Just created new directory. Looks ok?"
read enter
echo ""
cmd='cp -r html/html-base/* html/html-"$classcode"'
echo $cmd
eval $cmd
echo ""
cmd='ls -al html/html-"$classcode"'
echo $cmd
eval $cmd
echo "Copied base files to directory. Looks ok?"
read enter

# replace all the variables in the files with the passed in values"
echo ""
cmd="grep -rl \"##classcode##\" html/html-$classcode | xargs sed -i 's/##classcode##/$classcode/g'"
echo $cmd
eval $cmd
echo ""
echo "Command ran ok?"
read enter

cmd="grep -rl \"##clientid##\" html/html-$classcode | xargs sed -i 's/##clientid##/$clientid/g'"
echo $cmd
eval $cmd
echo ""
echo "Command ran ok?"
read enter

cmd="grep -rl \"##slidelink##\" html/html-$classcode | xargs sed -i 's/##slidelink##/$slidelink/g'"
echo $cmd
eval $cmd
echo ""
echo "Command ran ok?"
read enter

cmd="grep -rl \"##lablink##\" html/html-$classcode | xargs sed -i  's/##lablink##/$lablink/g'"
echo $cmd
eval $cmd
echo ""
echo "Command ran ok?"
read enter

cmd="grep -rl \"##startupdoclink##\" html/html-$classcode | xargs sed -i  's/##startupdoclink##/$startupdoclink/g'"
echo $cmd
eval $cmd
echo ""
echo "Command ran ok?"
read enter

cmd="grep -rl \"##repo##\" html/html-$classcode | xargs sed -i 's/##repo##/$repo/g'"
echo $cmd
eval $cmd
echo "Command ran ok?"
read enter

#Now copy recursively copy all the files and folders to the s3 bucket"
#rm html/html-"$classcode"/.DS*

cmd='aws s3 sync html/html-"$classcode" s3://"$classcode"-cloud.2ndsightlab.com --profile "$classcode"'
echo $cmd
eval ${cmd}
echo ""

#Invalidate the cloudfront distribution to make sure updates stick"
echo ""
cmd='aws cloudfront create-invalidation --distribution-id "$distroid" --paths "/*" --profile "$classcode"'
