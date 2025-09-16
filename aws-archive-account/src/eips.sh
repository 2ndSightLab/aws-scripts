#!/bin/bash -e
cat <<'END_TEXT'

***************************
Elastic IP Addresses (EIPs)
***************************
END_TEXT

read -p "Do you want to copy any EIPs? " copy

if [ "$copy" == "y" ]; then 

cat <<'END_TEXT'

You might want a record of the EIPs that may exist in
logs or have been used in firewall rules, DNS records,
or other configurations. Here is a list of the EIPs 
in this account: 

END_TEXT

aws ec2 describe-addresses --profile $archive_from --region $region \
  --query 'Addresses[*].{Name:Tags[?Key==`Name`].Value | [0], PublicIp:PublicIp}' --output text

read -p "If you want a record of the EIPs copy to a secret or parameter. Enter to continue. Ctrl-C to exit)" ok

fi #end if copy
copy=""
