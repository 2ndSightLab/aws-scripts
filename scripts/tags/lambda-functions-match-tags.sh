#!bin/bash 
#Find all the functions matching a list of tags where ANY of the tags match (not ALL required)
TAG_FILTER="Tag1=Value1|Tag2=Value2|Tag3=Value3|Tag4=Value4"

NAME_FILTER="kawabunga"
# ---------------------------------------


# This converts key1=1|key2=2 into "key1": "1"|"key2": "2"
SEARCH_PATTERN=$(echo "$TAG_FILTER" | sed 's/=/": "/g' | sed 's/|/|" /g' | sed 's/^/"/')

while IFS=$'\t' read -r name arn; do
    # Fetch tags exactly like your original script
    TAGS=$(aws lambda list-tags --resource "$arn" --profile pentester-role --region us-west-2)

    # CHECK: Name Match (Ignore Case) OR Tag Match
    if [[ "${name,,}" == *"${NAME_FILTER,,}"* ]] || echo "$TAGS" | grep -qE "$SEARCH_PATTERN"; then
        echo "Function: $name"
        echo "ARN: $arn"
        echo "Tags:"
        echo "$TAGS"
        echo "---"
    fi
done < functions.txt | tee target-functions.txt
