#move tools from the home directory since packer seems to croak trying to access those now

buildpath="/home/ec2-user/builder/2sl-ami"
tools=$buildpath/tools
scans=$tools/scans

mkdir $tools
mkdir $scans
mkdir $scans/nikto
mkdir $scans/wpscan

cp -r /home/ec2-user/tools/scans/nikto/*  $scans/nikto
cp -r /home/ec2-user/tools/scans/wpscan/* $scans/wpscan
