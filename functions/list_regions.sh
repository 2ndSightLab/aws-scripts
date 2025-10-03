#!/bin/bash

list_regions() {
    local PROFILE="$1"
    
    aws ec2 describe-regions --profile "$PROFILE" --no-cli-pager --color off --query 'Regions[].RegionName' --output text
}
