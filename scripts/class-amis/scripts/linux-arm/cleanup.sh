#!/bin/bash
echo '************************************'
echo 'cleanup'
echo '************************************'

#todo: change root user name so can rename ec2-user to root
#change the account name in /etc/passwd, /etc/shadow, /etc/group, and /etc/gshadow. 
#grep for the name root in /etc/ and modify postfix aliases file so that root was an alias to new account name
#need to change some configurations for logrotate

#clean up public ami for security reasons
#https://aws.amazon.com/articles/how-to-share-and-use-public-amis-in-a-secure-manner/
echo '**** remove keys and history ****'
echo '**** remove keys and history ****'
echo '**** remove keys and history ****'
echo '**** remove keys and history ****'
echo '**** remove keys and history ****'
echo '**** remove keys and history ****'
echo '**** remove keys and history ****'
echo '**** remove keys and history ****'
echo '**** remove keys and history ****'
echo '**** remove keys and history ****'


echo "users (should only be what is required):"
sudo cat /etc/passwd /etc/shadow | grep -E '^[^:]*:[^:]{3,}' | cut -d: -f1

echo "remove athorized keys"
#sudo rm -rf ~/.ssh/authorized_keys

echo "keys:"    
sudo find / -name "authorized_keys" -print -exec cat {} \;


#change password
#password USERNAME

#rm -rf ~/tools/downloads
#sudo find /root/.*history /home/*/.*history -exec sudo rm -f {} \; || echo "No history files found"
#sudo find / -name 'authorized_keys' –exec sudo rm –f {} \; || echo "No authorized keys found"
