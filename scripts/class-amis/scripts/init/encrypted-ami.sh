#need a script to give appropriate permissions for encrypted ami

#1 - create a kms key programmatically for encrypted amis
#2 - make the hacker-builder role used to run jobs to deploy stuff permissions to admin the key
#3 - may want a separate key admin later but for now this works
#4 - give the remote account permission to use the key
#5 - IAM permission to the user to use the key - through a role? How does this work w/SSO?

#https://aws.amazon.com/blogs/security/how-to-share-encrypted-amis-across-accounts-to-launch-encrypted-ec2-instances/

#permission to share the ami
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "ec2: ModifyImageAttribute",
            ],
            "Resource": [
                "arn:aws:ec2:us-east-1::image/<12345678>"
            ]
        }
 ] 
}

Add the other account - check

Add policy target account to use the key:

{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "kms:DescribeKey",
                "kms:ReEncrypt*",
                "kms:CreateGrant",
                "kms:Decrypt"
            ],
            "Resource": [
                "arn:aws:kms:us-east-1:<111111111111>:key/<key-id of cmkSource>"
            ]                                                    
        }
    ]
}

Link this policy up wtih my SSO hacker user..

Fricking A. Need to do all this
https://docs.aws.amazon.com/autoscaling/ec2/userguide/key-policy-requirements-EBS-encryption.html#policy-example-cmk-cross-account-access

#run this in pentester account
#grantee is role in pt account that can access the key
#how does this work with SSO????
aws kms create-grant \
  --region us-west-2 
  --key-id arn:aws:kms:us-west-2:444455556666:key/1a2b3c4d-5e6f-1a2b-3c4d-5e6f1a2b3c4d \
  --grantee-principal
arn:aws:iam::993539174985:role/aws-reserved/sso.amazonaws.com/us-east-2/AWSReservedSSO_Pentester_d2f07ce263b0cdcc
  --operations "Encrypt" "Decrypt" "ReEncryptFrom" "ReEncryptTo" "GenerateDataKey" "GenerateDataKeyWithoutPlaintext" "DescribeKey" "CreateGrant"

Need permission for EC2, S3, assign iam roles
