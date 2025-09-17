When I perform a penetration test I create a new AWS account standalone with spearate resources just for that test. 
That way, if something goes wrong, the impact is limited to the resources in that account, presuming I am using IAM 
users, roles and permissions specific to that one test.

After the test I want to archive those resources, so I wrote this script to do that.

In addition to archiving resources, sometimes you just want to move a bucket, parameter, secret, or AMI to another account. The script cand do that also.

It's important to test AMIs moved to new accounts and granted ownership in those accounts, so there's an option to do that as well. 
That requires starting a new image from the new AMI to make sure you have access to the KMS key used to encrypt
the AMI and the ability to login with whatever credentials you have assigned.

You'll probably also want to save money so there's an option to apply a lifecyle policy to an S3 bucket.

This is a work in progress so other options will be added as I need them.


8/21/25 - initial commit is to list the resources I want to archive. Automation is balanced with time it will take vs. manual effort. \
8/23/25 - S3 bucket archive to different account with different KMS key; ami copy working \
8/24/25 - Test ami after creation to make sure it actually works. The problem is the length of time it takes to create an AMI is quite long. Still testing. \
9/1/25 - Added profile for KMS in case KMS keys are in a separate account. Basically archiving all AMIs, S3 buckets and secrets in an account is working. \
9/2/25 - Moved testing AMI to a separate option to run after the AMI is available because it takes too long to wait. \
       - Added ability to apply lifecycle policy to S3 bucket. \
9/3/25 - Archive parameters with new encryption key
