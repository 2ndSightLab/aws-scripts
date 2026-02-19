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
S3_MALWARE_STATUS=$(aws guardduty get-malware-scan-settings --detector-id "$DETECTOR_ID" --region "$REGION" 2>/dev/null | jq -r 'if .ScanResourceCriteria.Include.S3_BUCKET_NAME then "ENABLED" else "NOT_ENABLED" end' || echo "NOT_CONFIGURED")

echo "========================================="
echo "GuardDuty Feature Status"
echo "========================================="
echo "Detector ID: $DETECTOR_ID"
echo "GuardDuty: $STATUS"
echo ""
echo "Data Sources:"
echo "$DETECTOR_INFO" | jq -r 'path(..) as $p | getpath($p) | select(type == "object" and has("Status")) | "\($p | join(".")): \(.Status)"' | grep "^DataSources"
echo ""
echo "Features:"
echo "$DETECTOR_INFO" | jq -r '.Features[]? | "\(.Name): \(.Status)", (.AdditionalConfiguration[]? | "  \(.Name): \(.Status)")'
echo "S3_MALWARE_SCAN: $S3_MALWARE_STATUS"
echo "========================================="

if [ "$S3_MALWARE_STATUS" != "ENABLED" ]; then
    exit 1
fi

