#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../functions/list_aws_services.sh"

if [[ -z "$PROFILE" ]]; then
    source "$SCRIPT_DIR/../select-aws-cli-profile/run.sh"
fi

if [[ -z "$SOURCE" ]]; then
    while true; do
        echo "Select listing source:"
        echo "1) help"
        echo "2) pricing"
        echo "3) support"
        echo "4) service-quotas"
        echo "5) iam"
        echo "6) organizations"
        echo "7) resource-explorer"
        read -p "Enter option (1-7): " OPTION
        case "$OPTION" in
            1) SOURCE="help"; break ;;
            2) SOURCE="pricing"; break ;;
            3) SOURCE="support"; break ;;
            4) SOURCE="service-quotas"; break ;;
            5) SOURCE="iam"; break ;;
            6) SOURCE="organizations"; break ;;
            7) SOURCE="resource-explorer"; break ;;
            *) echo "Invalid option. Please enter 1-7." ;;
        esac
    done
fi

echo "Available AWS services:"
list_aws_services "$SOURCE" "$PROFILE"
echo "---"
SERVICE_COUNT=$(list_aws_services "$SOURCE" "$PROFILE" | wc -l)
echo "Total services: $SERVICE_COUNT"
echo "---"

while true; do
    read -p "Select AWS service from the list above: " SERVICE
    if [[ -n "$SERVICE" ]]; then
        # Get the list of services and check if the selected service exists
        SERVICES_LIST=$(list_aws_services "$SOURCE" "$PROFILE")
        if echo "$SERVICES_LIST" | grep -q "^$SERVICE$"; then
            break
        else
            echo "Service '$SERVICE' not found in the list. Please try again."
        fi
    else
        echo "Please enter a service name."
    fi
done

echo "Selected service: $SERVICE"
