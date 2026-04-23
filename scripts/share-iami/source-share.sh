#!/bin/bash

# Set the destination account id for DEST_ACCOUTN_ID and run thi sin the source account
# Any KMS kesys used to ecrypt AMIs ened to be usable by the user that runs this and the copy script

set -uo pipefail

DEST_ACCOUNT_ID=""
REGION="us-east-2"

AMI_LIST=$(aws ec2 describe-images --owners self --query "Images[].ImageId" --output text --region $REGION --no-cli-pager)
RC=$?
if [ $RC -ne 0 ]; then
    echo "ERROR: Failed to list AMIs"
    return 1
fi

if [ -z "$AMI_LIST" ]; then
    echo "No AMIs found"
    return 0
fi

GRANTED_KEYS=""

for AMI in $AMI_LIST; do
    echo "Sharing AMI: $AMI"

    SNAP_INFO=$(aws ec2 describe-images --image-ids $AMI --query "Images[0].BlockDeviceMappings[].Ebs.[SnapshotId,KmsKeyId]" --output text --region $REGION --no-cli-pager)
    RC=$?
    if [ $RC -ne 0 ]; then
        echo "ERROR: Failed to get snapshots for $AMI"
        continue
    fi

    while read -r SNAP KEY; do
        if [ "$SNAP" = "None" ] || [ -z "$SNAP" ]; then
            continue
        fi

        echo "  Sharing snapshot: $SNAP"
        aws ec2 modify-snapshot-attribute --snapshot-id $SNAP --attribute createVolumePermission --operation-type add --user-ids $DEST_ACCOUNT_ID --region $REGION
        RC=$?
        if [ $RC -ne 0 ]; then
            echo "  ERROR: Failed to share $SNAP"
        fi

        if [ "$KEY" != "None" ] && [ -n "$KEY" ]; then
            ALREADY_GRANTED=0
            for GK in $GRANTED_KEYS; do
                if [ "$GK" = "$KEY" ]; then
                    ALREADY_GRANTED=1
                    break
                fi
            done
            if [ $ALREADY_GRANTED -eq 0 ]; then
                echo "  Granting KMS access: $KEY"
                aws kms create-grant --key-id $KEY --grantee-principal arn:aws:iam::${DEST_ACCOUNT_ID}:root --operations DescribeKey ReEncryptFrom CreateGrant --region $REGION --output json --no-cli-pager
                RC=$?
                if [ $RC -ne 0 ]; then
                    echo "  ERROR: Failed to grant KMS access for $KEY"
                fi
                GRANTED_KEYS="$GRANTED_KEYS $KEY"
            fi
        fi
    done <<< "$SNAP_INFO"

    aws ec2 modify-image-attribute --image-id $AMI --launch-permission '{"Add":[{"UserId":"'"$DEST_ACCOUNT_ID"'"}]}' --region $REGION
    RC=$?
    if [ $RC -ne 0 ]; then
        echo "  ERROR: Failed to share AMI $AMI"
    fi
done

echo "Done. Run copy-amis.sh in the destination account."
