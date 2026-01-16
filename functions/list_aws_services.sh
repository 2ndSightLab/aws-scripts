#!/bin/bash

list_aws_services() {
    local SOURCE="$1"
    local PROFILE="$2"
    
    if [[ -z "$SOURCE" ]]; then
        echo "Error: Source argument required (help, pricing, support, service-quotas, iam, organizations, resource-explorer)" >&2
        exit 1
    fi
    
    if [[ -z "$PROFILE" ]]; then
        echo "Error: Profile argument required" >&2
        exit 1
    fi
    
    case "$SOURCE" in
        "help")
            aws help | grep -A 10000 "AVAILABLE SERVICES" | grep "o " | sed 's/.*o //' | sort -u
            ;;
        "pricing")
            aws pricing describe-services --profile "$PROFILE" --region us-east-1 --no-cli-pager --color off | jq -r '.Services[] | select(.ServiceCode != null) | .ServiceCode' | sort -u
            ;;
        "support")
            SUPPORT_PLAN=$(aws support describe-severity-levels --profile "$PROFILE" --region us-east-1 --no-cli-pager --color off 2>/dev/null | jq -r '.severityLevels[0].name' 2>/dev/null)
            if [[ -z "$SUPPORT_PLAN" || "$SUPPORT_PLAN" == "null" ]]; then
                echo "Error: Support API requires Business or Enterprise support plan" >&2
                exit 1
            fi
            aws support describe-services --profile "$PROFILE" --region us-east-1 --no-cli-pager --color off | jq -r '.Services[]?.Code // empty' | sort -u
            ;;
        "service-quotas")
            aws service-quotas list-services --profile "$PROFILE" --region us-east-1 --no-cli-pager --color off | jq -r '.Services[].ServiceCode' | sort -u
            ;;
        "iam")
            aws iam get-account-authorization-details --profile "$PROFILE" --region us-east-1 --no-cli-pager --color off | jq -r '.Policies[].PolicyVersionList[].Document' | jq -r '.Statement[]?.Action[]?' | grep -E '^[a-z][a-z0-9-]+:' | cut -d':' -f1 | sort -u
            ;;
        "organizations")
            ORG_CHECK=$(aws organizations list-aws-service-access-for-organization --profile "$PROFILE" --region us-east-1 --no-cli-pager --color off 2>&1)
            if echo "$ORG_CHECK" | grep -q "AccessDeniedException\|AWSOrganizationsNotInUseException"; then
                echo "Error: No permission to access Organizations or account not part of an organization" >&2
                exit 1
            fi
            echo "$ORG_CHECK" | jq -r '.EnabledServicePrincipals[]?.ServicePrincipal // empty' | cut -d'.' -f1 | sort -u
            ;;
        "resource-explorer")
            aws resource-explorer-2 list-supported-resource-types --profile "$PROFILE" --region us-east-1 --no-cli-pager --color off | jq -r '.ResourceTypes[].ResourceType' | cut -d':' -f1 | sort -u
            ;;
        *)
            echo "Error: Invalid source '$SOURCE'. Valid options: help, pricing, support, service-quotas, iam, organizations, resource-explorer" >&2
            exit 1
            ;;
    esac
}
