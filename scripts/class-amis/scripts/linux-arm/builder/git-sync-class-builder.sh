#!/bin/bash -e

#get username and password from secrets parameter
user=""
pass=""

ami_type=$1
user=$2
pass=$3

if [ $# -eq 0 ]; then

	echo "Parameters required: ami_type user pass"
	exit
fi

echo '**** GITHUB SYNC ****'

function sync(){
	
	repo=$1
	echo 'sync '$repo
	cd /home/ec2-user/tools/2sl
	git clone https://$user:$pass@github.com/2ndSightLab/$repo.git
        cd $repo
        git remote set-url origin https://github.com/2ndSightLab/$repo.git
        git config credential.helper 'cache'
        
}

sync '2sl-fuzz'
sync '2sl-janitor'
sync '2sl-enum'

sudo yum install git -y

if [ \"$ami_type\" == \"PT\" ]; then
 	sync '2sl-reports'
	sync '2sl-recon'
fi

if [ \"$ami_type\" == \"Builder\" ]; then

	sync '2sl-reports'
	sync '2sl-pt'
	sync '2sl-ami'
	sync '2sl-lists'
	sync '2sl-c2'
	sync '2sl-recon'
fi

if [ \"$ami_type\" == \"Class-Builder\" ]; then
  sync '2sl-class'
	sync '2sl3000-labs'
fi

cd ~/tools
sudo chown -R ec2-user .
sudo chmod -R 700 .
echo '**** END GITHUB SYNC ****'

history -c

