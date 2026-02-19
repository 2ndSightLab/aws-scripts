#!/bin/bash
# Run this in CloudShell to validate that GuardDuty features are enabled
set -e

REGION="${AWS_REGION:-us-east-1}"

DETECTOR_ID=$(aws guardduty list-detectors --region "$REGION" --query 'DetectorIds[0]' --output text)

if [ "$DETECTOR_ID" = "None" ] || [ -z "$DETECTOR_ID" ]; then
    echo "ERROR: GuardDuty not enabled. Enable GuardDuty first."
    exit 1
fi

STATUS=$(aws guardduty get-detector --detector-id "$DETECTOR_ID" --region "$REGION" --query 'Status' --output text)

if [ "$STATUS" != "ENABLED" ]; then
    echo "ERROR: GuardDuty detector exists but is not enabled."
    exit 1
fi

DETECTOR_INFO=$(aws guardduty get-detector --detector-id "$DETECTOR_ID" --region "$REGION" --output json)
MALWARE_SETTINGS=$(aws guardduty get-malware-scan-settings --detector-id "$DETECTOR_ID" --region "$REGION" --output json 2>/dev/null || echo '{}')

S3_LOGS=$(echo "$DETECTOR_INFO" | jq -r '.DataSources.S3Logs.Status // "NOT_ENABLED"')
CLOUD_TRAIL=$(echo "$DETECTOR_INFO" | jq -r '.DataSources.CloudTrail.Status // "NOT_ENABLED"')
DNS_LOGS=$(echo "$DETECTOR_INFO" | jq -r '.DataSources.DnsLogs.Status // "NOT_ENABLED"')
FLOW_LOGS=$(echo "$DETECTOR_INFO" | jq -r '.DataSources.FlowLogs.Status // "NOT_ENABLED"')
KUBERNETES_AUDIT=$(echo "$DETECTOR_INFO" | jq -r '.DataSources.Kubernetes.AuditLogs.Status // "NOT_ENABLED"')
MALWARE_EC2=$(echo "$DETECTOR_INFO" | jq -r '.DataSources.MalwareProtection.ScanEc2InstanceWithFindings.EbsVolumes.Status // "NOT_ENABLED"')
MALWARE_S3=$(echo "$MALWARE_SETTINGS" | jq -r '.ScanResourceCriteria.Include // "NOT_CONFIGURED"' | grep -q "S3_BUCKET_NAME" && echo "ENABLED" || echo "NOT_ENABLED")

S3_DATA_EVENTS=$(echo "$DETECTOR_INFO" | jq -r '.Features[] | select(.Name=="S3_DATA_EVENTS") | .Status // "NOT_ENABLED"' | head -1)
[ -z "$S3_DATA_EVENTS" ] && S3_DATA_EVENTS="NOT_ENABLED"
EKS_AUDIT=$(echo "$DETECTOR_INFO" | jq -r '.Features[] | select(.Name=="EKS_AUDIT_LOGS") | .Status // "NOT_ENABLED"' | head -1)
[ -z "$EKS_AUDIT" ] && EKS_AUDIT="NOT_ENABLED"
EBS_MALWARE=$(echo "$DETECTOR_INFO" | jq -r '.Features[] | select(.Name=="EBS_MALWARE_PROTECTION") | .Status // "NOT_ENABLED"' | head -1)
[ -z "$EBS_MALWARE" ] && EBS_MALWARE="NOT_ENABLED"
RDS_LOGIN_EVENTS=$(echo "$DETECTOR_INFO" | jq -r '.Features[] | select(.Name=="RDS_LOGIN_EVENTS") | .Status // "NOT_ENABLED"' | head -1)
[ -z "$RDS_LOGIN_EVENTS" ] && RDS_LOGIN_EVENTS="NOT_ENABLED"
EKS_RUNTIME=$(echo "$DETECTOR_INFO" | jq -r '.Features[] | select(.Name=="EKS_RUNTIME_MONITORING") | .Status // "NOT_ENABLED"' | head -1)
[ -z "$EKS_RUNTIME" ] && EKS_RUNTIME="NOT_ENABLED"
LAMBDA_NETWORK=$(echo "$DETECTOR_INFO" | jq -r '.Features[] | select(.Name=="LAMBDA_NETWORK_LOGS") | .Status // "NOT_ENABLED"' | head -1)
[ -z "$LAMBDA_NETWORK" ] && LAMBDA_NETWORK="NOT_ENABLED"
RUNTIME_MONITORING=$(echo "$DETECTOR_INFO" | jq -r '.Features[] | select(.Name=="RUNTIME_MONITORING") | .Status // "NOT_ENABLED"' | head -1)
[ -z "$RUNTIME_MONITORING" ] && RUNTIME_MONITORING="NOT_ENABLED"

echo "========================================="
echo "GuardDuty Feature Status"
echo "========================================="
echo "Detector ID: $DETECTOR_ID"
echo "GuardDuty: $STATUS"
echo ""
echo "Data Sources (Legacy):"
echo "  CloudTrail: $CLOUD_TRAIL"
echo "  DNS Logs: $DNS_LOGS"
echo "  VPC Flow Logs: $FLOW_LOGS"
echo "  S3 Logs: $S3_LOGS"
echo "  Kubernetes Audit Logs: $KUBERNETES_AUDIT"
echo "  EC2 Malware Protection: $MALWARE_EC2"
echo ""
echo "Features:"
echo "  S3 Data Events: $S3_DATA_EVENTS"
echo "  S3 Malware Protection: $MALWARE_S3"
echo "  EKS Audit Logs: $EKS_AUDIT"
echo "  EBS Malware Protection: $EBS_MALWARE"
echo "  RDS Login Events: $RDS_LOGIN_EVENTS"
echo "  EKS Runtime Monitoring: $EKS_RUNTIME"
echo "  Lambda Network Logs: $LAMBDA_NETWORK"
echo "  Runtime Monitoring: $RUNTIME_MONITORING"
echo "========================================="

if [ "$MALWARE_S3" != "ENABLED" ]; then
    exit 1
fi

