#!/bin/bash

rm -rf /home/ec2-user/builder
mkdir /home/ec2-user/builder

echo '**** GITHUB SYNC ****'
#s=$(aws secretsmanager get-secret-value --secret-id 'ami-builder-secrets')
#t=$(echo $s | jq .SecretString | cut -d '"' -f5 | sed 's/\\//')
#gh auth login --with-token <<< $t

function sync(){
	
	repo=$1
	echo 'sync '$repo
	cd /home/ec2-user/builder
	git clone https://github.com/2ndSightLab/$repo.git
  cd $repo
  git remote set-url origin https://github.com/2ndSightLab/$repo.git
        
}

sync '2sl-fuzz'
sync '2sl-janitor'
sync '2sl-enum'
sync '2sl-reports'
sync '2sl-pt'
sync '2sl-ami'
sync '2sl-lists'
sync '2sl-c2'
sync '2sl-recon'

history -c
