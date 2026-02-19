#!/bin/bash
set -e

REGION="${AWS_REGION:-us-east-1}"

DETECTOR_ID=$(aws guardduty list-detectors --region "$REGION" --query 'DetectorIds[0]' --output text)

if [ "$DETECTOR_ID" = "None" ] || [ -z "$DETECTOR_ID" ]; then
    read -p "GuardDuty not enabled. Enable it? (y/n): " ENABLE
    if [ "$ENABLE" = "y" ]; then
        DETECTOR_ID=$(aws guardduty create-detector --enable --region "$REGION" --query 'DetectorId' --output text)
        echo "GuardDuty enabled: $DETECTOR_ID"
    else
        exit 1
    fi
fi

STATUS=$(aws guardduty get-detector --detector-id "$DETECTOR_ID" --region "$REGION" --query 'Status' --output text)

if [ "$STATUS" != "ENABLED" ]; then
    read -p "GuardDuty detector disabled. Enable it? (y/n): " ENABLE
    if [ "$ENABLE" = "y" ]; then
        aws guardduty update-detector --detector-id "$DETECTOR_ID" --enable --region "$REGION"
        echo "GuardDuty detector enabled"
    else
        exit 1
    fi
fi

DETECTOR_INFO=$(aws guardduty get-detector --detector-id "$DETECTOR_ID" --region "$REGION" --output json)
S3_MALWARE_STATUS=$(aws guardduty get-malware-scan-settings --detector-id "$DETECTOR_ID" --region "$REGION" 2>/dev/null | jq -r 'if .ScanResourceCriteria.Include.S3_BUCKET_NAME then "ENABLED" else "NOT_ENABLED" end' || echo "NOT_CONFIGURED")

echo "========================================="
echo "GuardDuty Feature Status"
echo "========================================="
echo "Detector ID: $DETECTOR_ID"
echo ""
echo "Data Sources:"
echo "$DETECTOR_INFO" | jq -r 'path(..) as $p | getpath($p) | select(type == "object" and has("Status")) | "\($p | join(".")): \(.Status)"' | grep "^DataSources"
echo ""
echo "Features:"
echo "$DETECTOR_INFO" | jq -r '.Features[]? | "\(.Name): \(.Status)", (.AdditionalConfiguration[]? | "  \(.Name): \(.Status)")'
echo "S3_MALWARE_SCAN: $S3_MALWARE_STATUS"
echo "========================================="

if [ "$S3_MALWARE_STATUS" != "ENABLED" ]; then
    read -p "S3 Malware Protection not enabled. Enable it? (y/n): " ENABLE
    if [ "$ENABLE" = "y" ]; then
        echo "Enter bucket name:"
        read BUCKET_NAME
        
        ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
        ROLE_NAME="GuardDutyS3MalwareProtectionRole"
        ROLE_ARN="arn:aws:iam::$ACCOUNT_ID:role/$ROLE_NAME"
        
        read -p "Is bucket encrypted with KMS? (y/n): " KMS_ENCRYPTED
        if [ "$KMS_ENCRYPTED" = "y" ]; then
            echo "Enter KMS key ID:"
            read KMS_KEY_ID
        else
            KMS_KEY_ID=""
        fi
        
        aws iam create-role --role-name "$ROLE_NAME" --assume-role-policy-document '{
          "Version": "2012-10-17",
          "Statement": [{
            "Effect": "Allow",
            "Principal": {"Service": "malware-protection-plan.guardduty.amazonaws.com"},
            "Action": "sts:AssumeRole"
          }]
        }' 2>/dev/null || echo "Role exists"
        
        cat > /tmp/policy-base.json <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {"Sid": "AllowManagedRuleToSendS3EventsToGuardDuty", "Effect": "Allow", "Action": ["events:PutRule", "events:DeleteRule", "events:PutTargets", "events:RemoveTargets"], "Resource": ["arn:aws:events:${REGION}:${ACCOUNT_ID}:rule/DO-NOT-DELETE-AmazonGuardDutyMalwareProtectionS3*"], "Condition": {"StringLike": {"events:ManagedBy": "malware-protection-plan.guardduty.amazonaws.com"}}},
    {"Sid": "AllowGuardDutyToMonitorEventBridgeManagedRule", "Effect": "Allow", "Action": ["events:DescribeRule", "events:ListTargetsByRule", "events:ListRules"], "Resource": ["arn:aws:events:${REGION}:${ACCOUNT_ID}:rule/DO-NOT-DELETE-AmazonGuardDutyMalwareProtectionS3*"]},
    {"Sid": "AllowPostScanTag", "Effect": "Allow", "Action": ["s3:PutObjectTagging", "s3:GetObjectTagging", "s3:PutObjectVersionTagging", "s3:GetObjectVersionTagging"], "Resource": ["arn:aws:s3:::${BUCKET_NAME}/*"]},
    {"Sid": "AllowEnableS3EventBridgeEvents", "Effect": "Allow", "Action": ["s3:PutBucketNotification", "s3:GetBucketNotification"], "Resource": ["arn:aws:s3:::${BUCKET_NAME}"]},
    {"Sid": "AllowPutValidationObject", "Effect": "Allow", "Action": ["s3:PutObject"], "Resource": ["arn:aws:s3:::${BUCKET_NAME}/malware-protection-resource-validation-object"]},
    {"Sid": "AllowGetBucketMetadata", "Effect": "Allow", "Action": ["s3:GetBucketLocation", "s3:GetBucketVersioning", "s3:ListBucket"], "Resource": ["arn:aws:s3:::${BUCKET_NAME}"]},
    {"Sid": "AllowMalwareScan", "Effect": "Allow", "Action": ["s3:GetObject", "s3:GetObjectVersion"], "Resource": ["arn:aws:s3:::${BUCKET_NAME}/*"]}
  ]
}
EOF
        
        if [ -n "$KMS_KEY_ID" ]; then
            POLICY_DOC=$(jq --arg region "$REGION" --arg account "$ACCOUNT_ID" --arg key "$KMS_KEY_ID" \
              '.Statement += [{"Sid": "AllowDecryptForMalwareScan", "Effect": "Allow", "Action": ["kms:GenerateDataKey", "kms:Decrypt"], "Resource": ("arn:aws:kms:" + $region + ":" + $account + ":key/" + $key), "Condition": {"StringEquals": {"kms:ViaService": ("s3." + $region + ".amazonaws.com")}}}]' \
              /tmp/policy-base.json)
        else
            POLICY_DOC=$(cat /tmp/policy-base.json)
        fi
        
        echo "$POLICY_DOC" | jq empty || { echo "ERROR: Invalid JSON policy"; exit 1; }
        
        aws iam put-role-policy --role-name "$ROLE_NAME" --policy-name "S3MalwareProtection" --policy-document "$POLICY_DOC"
        
        rm -f /tmp/policy-base.json
        
        if [ "$KMS_ENCRYPTED" = "y" ] && [ -n "$KMS_KEY_ID" ]; then
            echo "Updating KMS key policy..."
            
            # Get current policy and save to file
            aws kms get-key-policy --key-id "$KMS_KEY_ID" --policy-name default > /tmp/kms-response.json
            
            # Extract policy string, parse it, add statement, convert back to string
            jq -r '.Policy' /tmp/kms-response.json | \
              jq --arg role "$ROLE_ARN" --arg region "$REGION" \
              '.Statement += [{"Sid": "AllowGuardDutyMalwareProtection", "Effect": "Allow", "Principal": {"AWS": $role}, "Action": ["kms:Decrypt", "kms:GenerateDataKey"], "Resource": "*", "Condition": {"StringEquals": {"kms:ViaService": ("s3." + $region + ".amazonaws.com")}}}]' \
              > /tmp/kms-updated.json
            
            # Put updated policy
            aws kms put-key-policy --key-id "$KMS_KEY_ID" --policy-name default --policy file:///tmp/kms-updated.json
            
            rm /tmp/kms-response.json /tmp/kms-updated.json
        fi
        
        echo "Waiting for IAM propagation (30 seconds)..."
        sleep 30
        
        aws guardduty create-malware-protection-plan \
          --role "$ROLE_ARN" \
          --protected-resource "S3Bucket={BucketName=$BUCKET_NAME}" \
          --region "$REGION"
        
        echo "S3 Malware Protection enabled for bucket: $BUCKET_NAME"
    fi
fi
