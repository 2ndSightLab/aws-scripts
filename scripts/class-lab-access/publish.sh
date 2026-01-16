
#use this to generate the commans to execute
#the class prefix is unique to each class
echo "Enter classcode: "
read classcode
echo ""

if [ "" == $classcode ]; then
	echo "Not a valid classcode"
	exit
fi

echo "Enter commit message"
read msg

git pull
git add .
git commit -m "$msg"
git push

#echo "Enter cognito region: "
#read region
region=us-east-1
cognitopoolname="2sl-ClassRegistration-"$classcode

echo ""
cmd="aws cognito-idp list-user-pools --max-results 20 --profile "$classcode" --query 'UserPools[?Name==\`2sl-ClassRegistration-"$classcode"\`]'.Id --output text --region $region"
result="`eval ${cmd}`"
clientid=$(echo "$result")

if [ "$classcode" == "cloudy" ]; then
	domain=$classcode".2ndsightlab.com"
else
	domain=$classcode"-cloud.2ndsightlab.com"
fi

echo "domain: " $domain

cmd="aws cloudfront list-distributions --profile "$classcode" --query 'DistributionList.Items[?contains(Aliases.Items,\`$domain\`)].Id'"
result="`eval ${cmd}`"
distributionid=$(echo "$result")
distroid=$(echo $distributionid | sed 's/\[ "//' | sed 's/\" ]//')

echo "cloudfront distribution id "$distroid

#Now copy recursively copy all the files and folders to the s3 bucket"
# TO.DO REMOVE .DS_Store and only upload html and content folder"
cmd="aws s3 cp html/html-"$classcode" s3://"$domain" --recursive --profile "$classcode" --region "$region
result="`eval ${cmd}`"
echo "$result"

#Invalidate the cloudfront distribution to make sure updates stick"
cmd="aws cloudfront create-invalidation --distribution-id "$distroid" --paths \"/*\" --profile "$classcode
result="`eval ${cmd}`"
echo "$result"
