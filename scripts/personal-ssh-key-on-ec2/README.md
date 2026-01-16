# 2sl-handy-personal-ssh-key-on-ec2
Add your own SSH key to a Linux EC2 instance

Createa new ssh key on your system
ssh-keygen -t ed25519

Follow the prompts:
```
Generating public/private ed25519 key pair.
Enter file in which to save the key (/path/.ssh/id_ed25519): [file name]  
Enter passphrase for "[file name]" (empty for no passphrase): 
Enter same passphrase again: 
Your identification has been saved in hacker.key
Your public key has been saved in hacker.key.pub
The key fingerprint is:
SHA256:[key id] [email]
The key's randomart image is:
[IMAGE]
```
```
ls -al
```
You'll see:

```
[filename] (your file)
[filename].pub (your public key)
```

Backup your keys to a secure location.

Change the permissions on the private key.

```
chmod 400 [filename]
```

Add the public key to the EC2 instance.

https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/replacing-key-pair.html

Connect to the EC2 instance you want to connect to with your own SSH key.

Using a text editor of your choice, open the .ssh/authorized_keys file on the instance. 

```
vi ~/.ssh/authorized_keys
```

Paste the public key information from your new key pair underneath the existing public key information. 

Note that you can leave off the email.

Save the file.

You can also add it programmatically when creating an AMI.

You can leave the existing key as a backup or remove it if you are confident you will not lose your own key - AWS can't help you if you do.
                                    
Test connecting to your instance using your new key.

You will be asked to enter the passphrase you added ot the key.

Remember that if you change the underlying instance for a key you have created you will need to remove it from .ssh/known_hosts. I usually just delete that whole directory when usign the same key to connnect to a different instance. I've also written about the risks surrounding that error message here:

https://medium.com/cloud-security/warning-remote-host-identification-has-changed-30e0f4164160

Benefits and risks:
* Use the same key across a number of hosts. This is also a risk as an attacker only has to steal one key to get access to all.
* Requires a passphrase to access the host (though if it's easy to guess not that much help).
* Can use automation to periodically rotate the SSH keys (not saying it's easy and need to look into that a bit more - can AWS Secrets Manager do that?)
* If you lose the private key you created, AWS can't help you.
* BTW you can put your SSH key on a yubikey. :-)
