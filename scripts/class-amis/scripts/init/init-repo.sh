#!/bin/bash
#if the download dir does not exist create it
repodir=$HOME/repo
toolsdir=$repodir/tools
opsdir=$toolsdir/ops
tunnelsdir=$toolsdir/tunnels
practicedir=$toolsdir/practice
exploitdir=$toolsdir/exploits
dfirdir=$toolsdir/dfir
scansdir=$toolsdir/scans
listsdir=$toolsdir/lists

echo "Assume Packer Role"
#To get out of packer role unset credentials
#unset AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY AWS_SESSION_TOKEN
echo "------------------------------------------------"
assumerole="arn:aws:iam::453844007816:role/2sl-packer-role"
assumerolejson=$(aws sts assume-role --role-arn $assumerole  --role-session-name 2SLAMIBUILDERSESSION)
#echo $assumerolejson; echo "Assume role ok?"; read ok

echo "Set env var credentials and check identity"
echo "------------------------------------------------"
id=$(echo $assumerolejson | jq .Credentials.AccessKeyId | sed 's/"//g')
key=$(echo $assumerolejson | jq .Credentials.SecretAccessKey | sed 's/"//g')
session=$(echo $assumerolejson | jq .Credentials.SessionToken | sed 's/"//g')
#echo $id; echo $key; echo $session; echo "Values ok?"; read ok

export AWS_ACCESS_KEY_ID=$id
export AWS_SECRET_ACCESS_KEY=$key
export AWS_SESSION_TOKEN=$session
export AWS_REGION=us-east-2

aws sts get-caller-identity
echo "Idenity ok?"; read ok

function get_ssm_param(){ echo $(aws ssm get-parameter --query "Parameter.Value" --with-decryption --name $1 | sed 's/"//g'); }

bucket=$(get_ssm_param ami.builder.bucket --query Name --output text)
#bucket=$(get_ssm_param_value $bucket_param)
bucket_repo_folder='s3://'$bucket'/repo'
echo $bucket_repo_folder" ok?";read ok

#todo 
#vimrc file

function mdir {
    echo "Deleting and making directory "$1" OK? (ctrl-c to exit)"
    read ok
    rm -rf $1
    Mkdir $1
}

mdir $repodir
mdir $toolsdir
mdir $opsdir
mdir $tunnelsdir
mdir $practicedir
mdir $exploitdir
mdir $dfirdir
mdir $scansdir
mdir $listsdir

ls $toolsdir
echo "Directories OK? Ctrl-C to exit"
read ok

cd $tunnelsdir
git clone https://github.com/nccgroup/SocksOverRDP.git
git clone https://github.com/nccgroup/wstalker.git
git clone https://github.com/nccgroup/BinProxy
git clone https://github.com/iagox86/dnscat2
git clone https://github.com/inconshreveable/ngrok.git
git clone https://github.com/wangyu-/udp2raw-tunnel
git clone https://github.com/mmatczuk/go-http-tunnel
git clone https://github.com/cloudwu/mptun
git clone https://github.com/matiasinsaurralde/facebook-tunnel.git
git clone https://github.com/jpillora/chisel.git
git clone https://github.com/yarrick/iodine.git
git clone https://github.com/fatedier/frp.git
git clone https://github.com/inlets/inlets.git
git clone https://github.com/alestic/lambdash
cd $practicedir
git clone https://github.com/OWASP/Serverless-Goat.git
git clone https://github.com/RhinoSecurityLabs/cloudgoat.git
git clone https://github.com/nccgroup/sadcloud.git
cd $scansdir
git clone https://github.com/bridgecrewio/AirIAM.git
git clone https://github.com/evyatarmeged/Raccoon.git
git clone https://github.com/ethicalhackingplayground/Bug-Bounty-Tools
git clone https://github.com/tomnomnom/hacks
git clone https://github.com/tomnomnom/assetfinder.git
git clone https://github.com/nccgroup/house.git
git clone https://github.com/nccgroup/kube-auto-analyzer
git clone https://github.com/nccgroup/PMapper
git clone https://github.com/sullo/nikto
git clone https://github.com/cyberark/SkyArk.git
git clone https://github.com/wpscanteam/wpscan.git
git clone https://github.com/toniblyx/prowler.git
git clone https://github.com/awslabs/git-secrets
git clone https://github.com/nccgroup/featherduster
git clone https://github.com/duo-labs/cloudmapper.git
git clone https://github.com/nccgroup/go-pillage-registries
git clone https://github.com/jordanpotti/AWSBucketDump.git jordanpotti-AWSBucketDump
git clone https://github.com/netscylla/AWSBucketDump.git netscylla-AWSBucketDump
git clone https://github.com/RebootEx/AWSBucketDump.git RebootEx-AWSBucketDump
git clone https://github.com/awslabs/aws-security-benchmark.git
git clone https://github.com/eth0izzle/bucket-stream.git
git clone https://github.com/nccgroup/azucar.git
git clone https://github.com/microsoft/DevSkim
git clone https://github.com/nccgroup/G-Scout.git
git clone https://github.com/gwen001/s3-buckets-finder.git
git clone https://github.com/brianwarehime/inSp3ctor.git
git clone https://github.com/clarketm/s3recon.git
git clone https://github.com/koenrh/s3enum.git
git clone https://github.com/aaparmeggiani/s3find.git
git clone https://github.com/magisterquis/s3finder
git clone https://github.com/AnderEnder/s3find-rs.git
git clone https://github.com/pbnj/s3-fuzzer.git
git clone https://github.com/kromtech/s3-inspector.git
git clone https://github.com/sa7mon/S3Scanner.git
git clone https://github.com/bear/s3scan
git clone https://github.com/0xSearches/sandcastle.git
git clone https://github.com/cloudsploit/scans.git cloudsploit-scans
git clone https://github.com/nccgroup/Scout2.git
git clone https://github.com/GerbenJavado/LinkFinder.git
git clone https://github.com/disruptops/cred_scanner.git
git clone https://github.com/smiegles/mass3.git
git clone https://github.com/duo-labs/cloudtracker.git
git clone https://github.com/SecurityFTW/cs-suite.git
git clone https://github.com/m0rtem/CloudFail.git
git clone https://github.com/tomdev/teh_s3_bucketeers.git
git clone https://github.com/avineshwar/slurp.git avineshwar-slurp
git clone https://github.com/0xbharath/slurp.git 0xbharath-slurp
git clone https://github.com/stelligent/cfn_nag.git
git clone https://github.com/aboul3la/Sublist3r.git
cd $exploitdir
git clone https://github.com/daeken/SSRFTest
git clone https://github.com/nccgroup/autopwn.git
git clone https://github.com/nccgroup/clickjacking-poc
git clone https://github.com/nccgroup/gitpwnd
git clone https://github.com/nccgroup/singularity.git
git clone https://github.com/daeken/httprebind.git
git clone https://github.com/SpiderLabs/Responder.git
git clone https://github.com/s0md3v/XSStrike.git
git clone https://github.com/evilcos/xssor2
git clone https://github.com/DanMcInerney/xsscrapy.git
git clone https://github.com/beefproject/beef.git
git clone https://github.com/splunk/attack_range
git clone https://github.com/RhinoSecurityLabs/AWS-IAM-Privilege-Escalation.git
git clone https://github.com/dagrz/aws_pwn.git
git clone https://github.com/ropnop/serverless_toolkit.git
git clone https://github.com/RhinoSecurityLabs/ccat.git
git clone https://github.com/Static-Flow/CloudCopy.git
git clone https://github.com/cihanmehmet/cloudflarebypass.git
git clone https://github.com/MindPointGroup/cloudfrunt
git clone https://github.com/hausec/PowerZure.git
git clone https://github.com/prevade/cloudjack.git
git clone https://github.com/carnal0wnage/weirdAAL.git
git clone https://github.com/Prinzhorn/cloud-metadata-services.git
git clone https://github.com/CloudMitreAttack/CloudMitreAttack
git clone https://github.com/bostonlink/cloudPWN.git
git clone https://github.com/codemanki/cloudscraper.git
git clone https://github.com/RhinoSecurityLabs/Cloud-Security-Research.git Rhino-Cloud-Security-Research
git clone https://github.com/RhinoSecurityLabs/IPRotate_Burp_Extension.git
git clone https://github.com/andresriancho/nimbostratus.git
git clone https://github.com/RhinoSecurityLabs/pacu.git
git clone https://github.com/hisxo/gitGraber.git
git clone https://github.com/vanhauser-thc/thc-hydra
git clone https://github.com/nccgroup/Berserko
git clone https://github.com/nccgroup/hashcrack.git
cd $opsdir
git clone https://github.com/28mm/blast-radius.git
git clone https://github.com/Netflix/repokid.git
git clone https://github.com/sendgrid/krampus.git
git clone https://github.com/SumoLogic/sumologic-aws-lambda.git
git clone https://github.com/disruptops/resource-counter.git
git clone https://github.com/awslabs/aws-config-rules.git
git clone https://github.com/nccgroup/aws-inventory nccgroup-aws-inventory
git clone https://github.com/janiko71/aws-inventory janiko-aws-inventory
git clone https://github.com/turnerlabs/antiope
git clone https://github.com/tongueroo/aws-inventory.git tongueroo-aws-inventory
git clone https://github.com/powerupcloud/AWSInventoryLambda.git
git clone https://github.com/awslabs/cost-optimization-monitor.git
git clone https://github.com/awslabs/server-fleet-management-at-scale.git
git clone https://github.com/johndejager/AzureInventory.git
git clone https://github.com/polynimbus/polynimbus.git
git clone https://github.com/puppetlabs/puppetlabs-azure_inventory.git
git clone https://github.com/peetersm12/Office365Inventory-GUI.git
git clone https://github.com/louisbarrett/Eager-Locomotive.git
git clone https://github.com/te-papa/aws-key-disabler.git
git clone https://github.com/cloud-custodian/cloud-custodian.git
git clone https://github.com/RiotGames/cloud-inquisitor.git
git clone https://github.com/Netflix/repokid
git clone https://github.com/Netflix/security_monkey.git
cd $dfirdir
git clone https://github.com/toniblyx/aws-forensic-tools
git clone https://github.com/swimlane/CLAW.git
git clone https://github.com/loriendr/DFIR-AZURE-VOLATILITY.git
git clone https://github.com/ThreatResponse/aws_ir.git
git clone https://github.com/ThreatResponse/threatresponse_web.git
git clone https://github.com/awslabs/aws-security-automation.git
git clone https://github.com/prolsen/aws_responder
git clone https://github.com/Netflix-Skunkworks/diffy.git
cd $listsdir
git clone https://github.com/nccgroup/encoderama.git
git clone https://github.com/cujanovic/SSRF-Testing.git
git clone https://github.com/cujanovic/Content-Bruteforcing-Wordlist.git
git clone https://github.com/cujanovic/CRLF-Injection-Payloads.git
git clone https://github.com/cujanovic/Open-Redirect-Payloads.git
git clone https://github.com/fuzzdb-project/fuzzdb
git clone https://github.com/cujanovic/Markdown-XSS-Payloads.git
git clone https://github.com/payloadbox/xss-payload-list.git
git clone https://github.com/hyphendoodledocx/wordlist_generator.git
git clone https://github.com/berzerk0/Probable-Wordlists.git
git clone https://github.com/jeanphorn/wordlist
git clone https://github.com/danielmiessler/SecLists
git clone https://github.com/cr0hn/nosqlinjection_wordlists.git
git clone https://github.com/enaqx/awesome-pentest.git
git clone https://github.com/swisskyrepo/PayloadsAllTheThings.git
cd $toolsdir

echo "Removing git files from "$(pwd)" OK? Ctrl-C to exit"
read ok

find . \( -name ".git" -o -name ".gitignore" -o -name ".gitmodules" -o -name ".gitattributes" \) -exec rm -rf -- {} +

echo "Checking contents:"
ls

echo "uploading to S3"
aws s3 sync $toolsdir $bucket_repo_folder
