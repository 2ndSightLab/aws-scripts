sudo yum update -y
sudo yum install git -y
sudo yum install jq -y

#remove incorrect version of packer 
sudo rm -rf /usr/sbin/packer

#set tabstops to 2 in vim
#need to run tabs -2 before cat
echo "set tabstop=2" >> ~/.vimrc
