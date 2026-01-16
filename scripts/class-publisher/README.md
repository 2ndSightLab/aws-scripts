# 2SL-Class-Publisher

Publish class files from github to bitbucket. This gives teh students access to a class-specific repo so they cannot affect the original files should someone get access to the class repo - which happened to me during one particular class...nice job guys.

## Publishing
1. Install AWS Serverless Application Model - https://docs.aws.amazon.com/serverless-application-model/latest/developerguide/serverless-sam-cli-install.html
2. Create an S3 bucket for the Lambda application to live
```
aws s3 mb s3://<bucket-name>
```
3. Build the SAM Application
```
sam build 
```
4. Package the SAM Application
```
sam package --output-template packaged.yaml --s3-bucket <bucketname>
```
5. Deploy the Cloudformation Templates
```
aws cloudformation deploy --template-file ./packaged.yaml --stack-name <stack-name> --region <aws region> --capabilities CAPABILITY_IAM
```

Single Command
```
sam build  && sam package --output-template packaged.yaml --s3-bucket <bucketname> && aws cloudformation deploy --template-file ./packaged.yaml --stack-name <stack-name> --region <aws region> --capabilities CAPABILITY_IAM
```


## AMI-Share
API Key can be retrieved from AWS API Gateway console. The API is setup to share single AMI's and a bundle of linux, windows, and pfsense depending on what is passed in.

```
HEADERS
X-API-KEY: <api-key>

POST Prod/ami/share

{
    "account_id": "123456789 (Destination Account)// REQUIRED",
    "ami_name": "linux|windows|pfsense|wordpress // Optional"
}

RETURN
{
    "amis": [
        {
            "image_id": "ami-#######",
            "image_name": "Linux AMI",
            "image_shared_status": "completed"
        },
        {
            "image_id": "ami--#######",
            "image_name": "Windows AMI",
            "image_shared_status": "completed"
        },
        {
            "image_id": "ami--#######",
            "image_name": "PFSense AMI",
            "image_shared_status": "completed"
        }
    ],
    "dst_acct": "659596621645",
    "src_acct": "306115006586"
}
```

## Sharing Base Images [linux, windows, pfsense]
This will share the initial bundle of AMI's with the `account_id` that is passed in.

```
curl -X POST -H "x-api-key: <api key from AWS console>" -H "Content-Type: application/json" -d '{"account_id":"659596621645"}' https://8zvsef8124.execute-api.us-west-2.amazonaws.com/Prod/ami/share

RETURN
{
    "amis": [
        {
            "image_id": "ami-#######",
            "image_name": "Linux AMI",
            "image_shared_status": "completed"
        },
        {
            "image_id": "ami-#######",
            "image_name": "Windows AMI",
            "image_shared_status": "completed"
        },
        {
            "image_id": "ami-#######",
            "image_name": "PFSense AMI",
            "image_shared_status": "completed"
        }
    ],
    "dst_acct": "659596621645",
    "src_acct": "306115006586"
}
```

## Share single AMI [linux or windows or pfsense or wordpress]
This will share a single ami (`ami_name`) with the `account_id` that is passed in.

```
curl -X POST -H "x-api-key: <api key from AWS console>" -H "Content-Type: application/json" -d '{"account_id":"659596621645", "ami_name": "wordpress"}' https://8zvsef8124.execute-api.us-west-2.amazonaws.com/Prod/ami/share

RETURN
{
    "amis": [
        {
            "image_id": "ami-#######",
            "image_name": "Wordpress AMI",
            "image_shared_status": "completed"
        }
    ],
    "dst_acct": "659596621645",
    "src_acct": "306115006586"
}
```
