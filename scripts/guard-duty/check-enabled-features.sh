#!/bin/bash
# Run this in CloudShell to validate that GuardDuty features are enabled
set -e

REGION="${AWS_REGION:-us-east-1}"

DETECTOR_ID=$(aws guardduty list-detectors --region "$REGION" --query 'DetectorIds[0]' --output text)

if [ "$DETECTOR_ID" = "None" ] || [ -z "$DETECTOR_ID" ]; then
    echo "GuardDuty not enabled. Enabling..."
    DETECTOR_ID=$(aws guardduty create-detector --enable --region "$REGION" --query 'DetectorId' --output text)
fi

STATUS=$(aws guardduty get-detector --detector-id "$DETECTOR_ID" --region "$REGION" --query 'Status' --output text)

if [ "$STATUS" != "ENABLED" ]; then
    aws guardduty update-detector --detector-id "$DETECTOR_ID" --enable --region "$REGION"
    STATUS="ENABLED"
fi

DETECTOR_INFO=$(aws guardduty get-detector --detector-id "$DETECTOR_ID" --region "$REGION" --output json)

S3_LOGS=$(echo "$DETECTOR_INFO" | jq -r '.DataSources.S3Logs.Status // "NOT_ENABLED"')
KUBERNETES=$(echo "$DETECTOR_INFO" | jq -r '.DataSources.Kubernetes.AuditLogs.Status // "NOT_ENABLED"')
MALWARE_PROTECTION=$(echo "$DETECTOR_INFO" | jq -r '.DataSources.MalwareProtection.ScanEc2InstanceWithFindings.EbsVolumes.Status // "NOT_ENABLED"')
RDS_LOGIN=$(echo "$DETECTOR_INFO" | jq -r '.DataSources.RdsLoginActivity.Status // "NOT_ENABLED"')
EKS_RUNTIME=$(echo "$DETECTOR_INFO" | jq -r '.DataSources.Kubernetes.RuntimeMonitoring.Status // "NOT_ENABLED"')
LAMBDA_NETWORK=$(echo "$DETECTOR_INFO" | jq -r '.DataSources.LambdaNetworkLogs.Status // "NOT_ENABLED"')

echo "========================================="
echo "GuardDuty Feature Status"
echo "========================================="
echo "Detector ID: $DETECTOR_ID"
echo "GuardDuty: $STATUS"
echo "S3 Logs: $S3_LOGS"
echo "Kubernetes Audit Logs: $KUBERNETES"
echo "Malware Protection (EC2): $MALWARE_PROTECTION"
echo "RDS Login Activity: $RDS_LOGIN"
echo "EKS Runtime Monitoring: $EKS_RUNTIME"
echo "Lambda Network Logs: $LAMBDA_NETWORK"
echo "========================================="
