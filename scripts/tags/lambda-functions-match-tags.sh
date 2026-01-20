#!bin/bash 
#Find all the functions matching a list of tags where ANY of the tags match (not ALL required)
#AND a part fo the name (which you can set to nonsense if you only want to filter on tags - I use name for validation)
TAG_FILTER="Tag1=Value1|Tag2=Value2|Tag3=Value3|Tag4=Value4"
PROFILE="your profile name"
NAME_FILTER="kawabunga"
REGION="us-west-2"
# ---------------------------------------

aws lambda list-functions --query 'Functions[*].[FunctionName,FunctionArn]' --output text --profile $PROFILE --region $REGION > functions.txt

# This converts key1=1|key2=2 into "key1": "1"|"key2": "2"
SEARCH_PATTERN=$(echo "$TAG_FILTER" | sed 's/=/": "/g' | sed 's/|/|" /g' | sed 's/^/"/')

while IFS=$'\t' read -r name arn; do
    # Fetch tags exactly like your original script
    TAGS=$(aws lambda list-tags --resource "$arn" --profile $PROFILE --region $REGION)

    # CHECK: Name Match (Ignore Case) OR Tag Match
    if [[ "${name,,}" == *"${NAME_FILTER,,}"* ]] || echo "$TAGS" | grep -qE "$SEARCH_PATTERN"; then
        echo "Function: $name"
        echo "ARN: $arn"
        echo "Tags:"
        echo "$TAGS"
        echo "---"
    fi
done < functions.txt | tee target-functions.txt
