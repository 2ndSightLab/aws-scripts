#!/bin/bash -e
cat <<'END_TEXT'

******************************

Apply lifecylde rule S3 Bucket

Blogs:
https://medium.com/cloud-security/analyzing-costs-of-aws-implementation-and-finding-valid-configuration-values-with-the-aws-cli-2d3dfdabb1ef
https://medium.com/@2ndsightlab/a-script-to-apply-a-lifecycle-rule-to-an-s3-bucket-a2817a33f1b7

******************************
END_TEXT

aws configure list-profiles
echo ""
read -p "Enter the CLI profile to use to apply the lifecycle policy: " profile
read -p "Enter the region in which the bucket exists where you want to apply the rule: " region

echo "S3 buckets in account:"
#echo ""
#aws s3 ls --profile $profile --region $region | cut -d ' ' -f3
echo ""

printf "%-45s | %-15s | %-20s\n" "BUCKET NAME" "HAS LIFECYCLE" "STORAGE CLASS" && printf "%-45s-+-%-15s-+-%-20s\n" "---------------------------------------------" "---------------" "--------------------" && aws s3api list-buckets --profile $profile --region $region --query "Buckets[].Name" --output text | tr '\t' '\n' | while read bucket; do 
  has_lifecycle=$(aws s3api get-bucket-lifecycle-configuration --profile $profile --region $region --bucket "$bucket" >/dev/null 2>&1 && echo "Y" || echo "N")
  storage_class=$(aws s3api get-bucket-lifecycle-configuration --profile $profile --region $region --bucket "$bucket" 2>/dev/null | jq -r '.Rules[]?.Transitions[]?.StorageClass // empty' 2>/dev/null | paste -sd, - || echo "None")
  printf "%-45s | %-15s | %-20s\n" "$bucket" "$has_lifecycle" "$storage_class"
done


echo ""
read -p "Enter the name of the S3 bucket to which you want to apply the policy: " bucket
echo ""
echo "Here is a list of possible storage classes for your life cycle rule and associated costs:"

case $region in
     "us-east-1") location="US East (N. Virginia)" ;;
     "us-east-2") location="US East (Ohio)" ;;
     "us-west-1") location="US West (N. California)" ;;
     "us-west-2") location="US West (Oregon)" ;;
     "eu-west-1") location="Europe (Ireland)" ;;
     "eu-central-1") location="Europe (Frankfurt)" ;;
     "ap-southeast-1") location="Asia Pacific (Singapore)" ;;
     "ap-northeast-1") location="Asia Pacific (Tokyo)" ;;
     *) location="US East (N. Virginia)" ;;  # Default fallback
 esac

aws pricing get-products --profile $profile --service-code AmazonS3 --filters "Type=TERM_MATCH,Field=productFamily,Value=Storage" "Type=TERM_MATCH,Field=location,Value=$location" --format-version aws_v1 --region us-east-1 | \
jq -r '.PriceList | map(fromjson) | map(select(.terms.OnDemand)) | map({
   storageClass: .product.attributes.storageClass,
   location: .product.attributes.location,
   descriptions: [.terms.OnDemand | to_entries[] | .value.priceDimensions | to_entries[] | .value | select(.endRange == "Inf") | .description]
 }) | map({
   storageClass: .storageClass,
   location: .location,
   description: (.descriptions | join("; "))
 }) | unique | sort_by(.storageClass, .description) | (["STORAGE CLASS (for JSON)", "LOCATION", "DESCRIPTION"] | @tsv), (.[] | [.storageClass, .location, .description] | @tsv)' | column -t -s $'\t'

echo ""
cat <<'END_TEXT'

**************NOTE******************
At the time of this writing there seems to be a bug in the AWS pricing API. No matter how I query the price for the DEEP_ARCHIVE option will not come up. I wrote a blog post about this and Q is telling me there is a separate storage class which should apparently be showing up here. If you run this at a later date perhaps it will be fixed by then.

If you are looking for the cheapest storage class (price per GB stored), you can create a lifecycle policy for one day and choose DEEP_ARCHIVE to transition in one day for data you will not be accessing again. 

CAVEATS:

* There is a one time fee to transfer items to a new storage class.
* By default the lowest size transfered is 128KB. If you have items smaller you can override that but the cost may not be worth it.
* If you need to retrieve the data, you will pay other fees that may make the cost not worth the transfer depending on your access patterns.
* If you choose intelligent tiering your data might not transition to a lower cost tier for 180 days. So it is cheaper to move straight to DEEP_ARCHIVE if you never plan to look at the data again (except in case of emergency which hopefully never happens.)
* If you transfer the data to DEEP_ARCHIVE you have to leave it there for at least 180 days (meaning you can't save money by deleting it).
* READ THE PRICING PAGE IN CASE ANY OF THIS HAS CHANGED.


***********************************

END_TEXT

read -p "Would you like to see ALL the fees associate with S3 for this region from the pricing API? (y): " view

if [ "$view" == "y" ]; then 
echo ""
aws pricing get-products --profile $profile --service-code AmazonS3  --filters "Type=TERM_MATCH,Field=location,Value=$location" --format-version aws_v1 --region us-east-1 | \
jq -r '.PriceList | map(fromjson) | map({
   storageClass: .product.attributes.storageClass,
   location: .product.attributes.location,
   descriptions: [.terms.OnDemand | to_entries[] | .value.priceDimensions | to_entries[] | .value | select(.endRange == "Inf") | .description]
 }) | map({
   storageClass: .storageClass,
   location: .location,
   description: (.descriptions | join("; "))
 }) | unique | sort_by(.storageClass, .description) | (["STORAGE CLASS", "LOCATION", "DESCRIPTION"] | @tsv), (.[] | [.storageClass, .location, .description] | @tsv)' | column -t -s $'\t'
echo ""
fi

echo "Valid storage class values:"
echo ""
aws s3api put-bucket-lifecycle-configuration help 2>/dev/null | grep "StorageClass" | grep "DEEP_ARCHIVE" | sed 's/,//g' | sed 's/^[[:space:]]*//' | uniq

echo ""
read -p "Enter a storage class value: " sc
echo ""

read -p "In how many days do you want to migrate your bucket to the new storage class? " days
echo ""
echo "Apply lifecycle policy"

id="move-to-$sc-in-$days-days"

cat > /tmp/policy.json << EOF
{
   "Rules": [
     {
        "ID": "$id",
        "Filter": {},
        "Status": "Enabled",
        "Transitions": [
           {
              "Days": $days,
              "StorageClass": "$sc"
           }
        ]
     }
   ]
}
EOF

cat /tmp/policy.json

aws s3api put-bucket-lifecycle-configuration \
    --bucket "$bucket" \
    --profile $profile --region $region \
    --lifecycle-configuration "file:///tmp/policy.json"
