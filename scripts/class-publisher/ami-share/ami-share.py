import json
import os
import logging
import boto3
from botocore.exceptions import ClientError


logger = logging.getLogger()
logger.setLevel(logging.INFO)

LINAMINAMEPART = "2nd-Sight-Lab-AMZNLN2-*"
WINAMINAMEPART = "2nd-Sight-Lab-WIN2016-*"
PFSENSEAMINAMEPART = "2nd-Sight-Lab-pfsense-*"
WPAMINAMEPART = "2nd-Sight-Lab-Wordpress-*"

def lambda_handler(event, context):
    # Obtain AcctNumber from ARN
    fxn_arn = context.invoked_function_arn
    self_acct_id = fxn_arn.split(":")[4]
    logger.info("Account ID: {}".format(self_acct_id))

    body = json.loads(event["body"])
    logger.info("Request: {}".format(body))

    # Determine the payload objects sent in
    if checkKey(body, "account_id"):
        if checkKey(body, "ami_name"):
            ami_name = body["ami_name"].lower()
            if ami_name in ["windows", "linux", "pfsense", "wordpress"]:
                if ami_name in "windows":
                    PREFIX = WINAMINAMEPART
                elif ami_name in "linux":
                    PREFIX = LINAMINAMEPART
                elif ami_name in "pfsense":
                    PREFIX = PFSENSEAMINAMEPART
                elif ami_name in "wordpress":
                    PREFIX = WPAMINAMEPART
                
                ami_id = getAmiId(PREFIX, self_acct_id)
                shared = shareAmiById(ami_id, body["account_id"])

                return {
                    "statusCode": 200,
                    "body": json.dumps({
                        "dst_acct": body["account_id"],
                        "src_acct": self_acct_id,
                        "amis": [
                            {
                                "image_name": ami_name.capitalize() + " AMI",
                                "image_id": ami_id,
                                "image_shared_status": shared
                            }
                        ]
                    })
                }
                
            else:

                return {
                    "statusCode": 400,
                    "body": json.dumps({
                        "error": "The image name you specified is not valid. Please use windows, linux, pfsense, or wordpress"
                    })
                }
            
        else:
            ret = shareBaseAmis(body["account_id"], self_acct_id)

            return {
                "statusCode": 200,
                "body": json.dumps({
                    "dst_acct": body["account_id"],
                    "src_acct": self_acct_id,
                    "amis": ret
                })
            }


    return {
        "statusCode": 200,
        "body": json.dumps({
            "message": "hello world",
            # "location": ip.text.replace("\n", "")
        }),
    }

# Share the base AMI's - LIN, WIN, PFSENSE
def shareBaseAmis(account_id, self_acct_id):
    linami = getAmiId(LINAMINAMEPART, self_acct_id)
    winami = getAmiId(WINAMINAMEPART, self_acct_id)
    pfsenseami = getAmiId(PFSENSEAMINAMEPART, self_acct_id)

    linsh = shareAmiById(linami, account_id)
    winsh = shareAmiById(winami, account_id)
    pfsensesh = shareAmiById(pfsenseami, account_id)

    return [
        {
            "image_name": "Linux AMI",
            "image_id": linami,
            "image_shared_status": linsh
        },
        {
            "image_name": "Windows AMI",
            "image_id": winami,
            "image_shared_status": winsh
        },
        {
            "image_name": "PFSense AMI",
            "image_id": pfsenseami,
            "image_shared_status": pfsensesh
        }
    ]

# Get Latest AMI Id with Filter
def getAmiId(ami_filter, self_acct_id):
    client = boto3.client('ec2')

    response = client.describe_images(
        Filters=[
            {
                'Name': 'name',
                'Values': [
                    ami_filter,
                ]
            },
        ],
        Owners=[
            self_acct_id,
        ],
    )

    try:
        latest_ami = getLatestAmiFromList(response["Images"])
        logging.info("Sharing AMI {} for filter {}".format(latest_ami["ImageId"], ami_filter))

        return latest_ami["ImageId"]
    except:
        return "Error Finding AMI"

# Share AMI Function
def shareAmiById(amid_id, acct_id):
    client = boto3.client('ec2')
    try: 
        response = client.modify_image_attribute(
            ImageId=amid_id,
            LaunchPermission={
                'Add': [
                    {
                        'UserId': acct_id
                    },
                ]
            }
        )

        return "completed"
    except:
        return "Error sharing AMI"


# Sort & Return first var
def getLatestAmiFromList(list):
    sorted_list = sorted(list, key = lambda i: i['CreationDate'], reverse=True)

    return sorted_list[0]

# Checks if key present in dict
def checkKey(dict, key): 
    if key in dict.keys(): 
        return True 
    else: 
        return False