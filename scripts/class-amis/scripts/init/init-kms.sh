#create a new CMK in the current account named builder_cmk if doesn't exist
aws kms create-key --key-usage ENCRYPT_DECRYPT --origin AWS_KMS

echo "TODO: change the key policy to include 2sl-Builder"
echo "TODO: separate AMI building acct, or add a new pt acct if I hire others."
