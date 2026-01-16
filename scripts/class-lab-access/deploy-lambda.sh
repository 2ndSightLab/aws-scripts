echo "Enter profile:" 
read profile

lambda='CLS-2SL3000-montreal-lambda-RegistrationLambda-1SGBY2U6CM8L'

cd auth-py
pip3 freeze > requirements.txt
pip3 install --upgrade -r requirements.txt -t .
python3 -m pip3 install --target ./package cffi --upgrade
rm freeze 
zip -r9 ../auth-py.zip .
cd ..

#attempt update
aws lambda update-function-code --function-name $lambda --zip-file fileb://auth-py.zip --region us-east-1 --profile $profile

aws lambda update-function-code --function-name $lambda --zip-file fileb://auth-py.zip --region us-east-2 --profile $profile

aws lambda update-function-code --function-name $lambda --zip-file fileb://auth-py.zip --region us-west-2 --profile $profile

aws lambda update-function-code --function-name $lambda --zip-file fileb://auth-py.zip --region us-west-1 --profile $profile

aws lambda update-function-code --function-name $lambda --zip-file fileb://auth-py.zip --region ca-central-1 --profile $profile

aws lambda update-function-code --function-name $lambda --zip-file fileb://auth-py.zip --region us-central-1 --profile $profile

#attempt create (fix this later)

region='us-east-1'
rolename='AuthLambda-us-east-1'
rolearn='arn:aws:iam::035577010687:role/AuthLambda-us-east-1'

#aws cloudformation create-stack --stack-name $rolename-$region --template-body=file://cfn/registration-iam-auth-region-role.yaml --profile $profile --region $region --capabilities CAPABILITY_NAMED_IAM

aws lambda create-function --function-name $lambda --role $rolearn --runtime python3.7 --handler verify-jwt.lambda_handler --zip-file fileb://auth-py.zip --region $region --profile $profile

region='us-west-2'

#aws cloudformation create-stack --stack-name $rolename --template-body=file://cfn/registration-iam-auth-region-role.yaml --profile $profile --region $region --capabilities CAPABILITY_NAMED_IAM

aws lambda create-function --function-name $lambda --role $rolearn --runtime python3.7 --handler verify-jwt.lambda_handler --zip-file fileb://auth-py.zip --region $region --profile $profile

region='us-east-2'

aws lambda create-function --function-name $lambda --role $rolearn --runtime python3.7 --handler verify-jwt.lambda_handler --zip-file fileb://auth-py.zip --region $region --profile $profile

region='us-west-1'

aws lambda create-function --function-name $lambda --role $rolearn --runtime python3.7 --handler verify-jwt.lambda_handler --zip-file fileb://auth-py.zip --region $region --profile $profile

region='ca-central-1'

aws lambda create-function --function-name $lambda --role $rolearn --runtime python3.7 --handler verify-jwt.lambda_handler --zip-file fileb://auth-py.zip --region $region --profile $profile

aws ec2 describe-regions | grep 'us-'
