
#modify this to be called from an outer file that grabs accounts
#one at a time from a list and gets the API key from a secret param
#created at time of API creation in new account

#so a person really needs to ever see or know the API key used to share
#the AMIs
echo "Enter account id"
read accountid

apikey="\"x-api-key: xxxxxxxxxxxxxxxxxxxxxxxxxxxxx\""
account="'{\"account_id\":\"$accountid\"}'"
content="\"Content-Type: application/json"\"
url=https://zreq17g747.execute-api.us-west-2.amazonaws.com/dev/ami/share

cmd="curl -X POST -H $apikey -H $content -d $account $url"

eval $cmd

echo ""
echo ""
