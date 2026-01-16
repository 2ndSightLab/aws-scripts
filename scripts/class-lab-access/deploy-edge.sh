echo "Enter profile:"
read profile

cd auth-edge
#pip3 freeze > requirements.txt
#pip3 install --upgrade -r requirements.txt -t .
#rm freeze 
zip -r9 ../edge-py.zip .
cd ..
function='2SL3000-edge'

aws lambda update-function-code --function-name $function --zip-file fileb://edge-py.zip --profile $profile
