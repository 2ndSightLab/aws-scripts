#!/bin/bash -e
cat <<'END_TEXT'

***************************
SSH KEY Pairs
***************************

END_TEXT

echo "Here are a list of the EC2 SSH keys:"
echo ""
aws ec2 describe-key-pairs --profile $archive_from region $region
echo ""
echo "Add the values of EC2 keys to Secrets Manager before archiving secrets"
echo "if you want to retain the value of the key pairs. Note that you will"
echo "have to obtain the private key from wherever it is stored. Also"
echo "this command does not take into account key pairs created outside"
echo "the AWS EC2 console."
echo ""
echo "Enter to continue. Ctrl-C to exit."
