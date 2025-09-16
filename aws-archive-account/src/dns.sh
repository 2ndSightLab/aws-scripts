#!/bin/bash -e
cat <<'END_TEXT'

***************************
DNS
***************************
END_TEXT

read -p "Do you want to copy any DNS (Route 53) records? " copy
if [ "$copy" == "y" ]; then 

cat <<'END_TEXT'

This is a manual step because DNS records can be
configured in different ways for different purposes
Check DNS records associated with:

  * EC2 instances (such as for a TLS certificate associated with RDP or test webapps)"
  * Email addresses
  * Lambda functions
  * ALBs, ELBs, NLBs
  * CloudFront or some other CDN
  * Any other place you used a custom domain name

Record how you used the domain name in parameter store or secrest manager.
If you are done with the DNS record terminate it so it can no be used
via subdomain takeover.

Domain names and hosted zones are listed below.

END_TEXT

echo "Domain names:"
echo ""
aws route53domains list-domains --region us-east-1 --output text --query "Domains[*].DomainName" \
  --profile $archive_from --region us-east-1
echo ""
echo "Hosted Zones:"
echo ""
aws route53 list-hosted-zones --query "HostedZones[*].[Id, Name]" --output text \
  --profile $archive_from --region us-east-1
echo ""
read -p "Enter to continue. Ctrl-C to exit." ok

fi #end if copy
copy=""
