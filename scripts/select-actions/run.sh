#!/bin/bash

# Either set SERVICE before including this script, or the user will be asked to specify a service
# This script calls the list_actions function in ../functions/list_actions.sh passing in SERVICE
# The function lists the available actions for an AWS service to use in a policy 
# Then it loops through and lets the user select actions for an AWS policy
# It returns an ACTIONS variable which is the list of actions, separated by commas

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Check if SERVICE is set, if not call select-aws-service script
if [[ -z "$SERVICE" ]]; then
    source "$SCRIPT_DIR/../select-aws-service/run.sh"
fi

# Check if PROFILE is set, if not call select-aws-cli-profile script
if [[ -z "$PROFILE" ]]; then
    source "$SCRIPT_DIR/../select-aws-cli-profile/run.sh"
fi

# Source the list_actions function
source "$SCRIPT_DIR/../../functions/list_actions.sh"

# Get available actions for the service
AVAILABLE_ACTIONS=$(list_actions "$SERVICE" "$PROFILE")

if [[ -z "$AVAILABLE_ACTIONS" ]]; then
    echo "No actions found for service: $SERVICE"
    exit 1
fi

echo "Available actions for $SERVICE:"
echo "$AVAILABLE_ACTIONS"
echo "---"

# Initialize ACTIONS array
SELECTED_ACTIONS=()

# Loop to select actions
while true; do
    echo "Enter when done adding actions: Enter action to add (or 'done' to finish, 'list' to see available actions again):"
    read -p "> " ACTION_INPUT
    
    if [[ -z "$ACTION_INPUT" ]] || [[ "$ACTION_INPUT" == "done" ]]; then
        break
    elif [[ "$ACTION_INPUT" == "list" ]]; then
        echo "$AVAILABLE_ACTIONS"
        continue
    else
        # Check if action exists in available actions
        if echo "$AVAILABLE_ACTIONS" | grep -q "^$ACTION_INPUT$"; then
            SELECTED_ACTIONS+=("$ACTION_INPUT")
            echo "Added: $ACTION_INPUT"
        else
            echo "Action not found. Please select from the available actions."
        fi
    fi
done

# Convert array to comma-separated string
ACTIONS=$(IFS=','; echo "${SELECTED_ACTIONS[*]}")
