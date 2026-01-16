#echo "Enter classcode: "
#read classcode
classcode="chicago202001"
echo "Enter email (like info@2ndsightlab.com): "
read email

#lookup the userpool id - make sure only one in acct because uses first one
userpoolid=$(aws cognito-idp list-user-pools --max-results 20 \
--profile chicago202001 --query UserPools[0].Id)

userpoolid=$(echo ${userpoolid} | sed 's/"//g')
echo ""
echo "Cognito User Pool ID: "${userpoolid}
echo ""
aws cognito-idp admin-create-user \
--user-pool-id ${userpoolid} \
--username ${email} \
--desired-delivery-mediums 'EMAIL' \
--user-attributes Name=email,Value=${email} Name=email_verified,Value=true \
--profile $classcode
