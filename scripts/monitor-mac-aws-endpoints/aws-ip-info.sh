#!/bin/bash
# aws-ip-info.sh

AWS_FILE="ip-ranges.json"

# 1. Update check (2 hours)
#if [[ ! -f "$AWS_FILE" ]] || [[ -n $(find "$AWS_FILE" -mmin +120) ]]; then
#    curl -s -f -o "$AWS_FILE" https://ip-ranges.amazonaws.com || { echo "ERROR: Download failed"; return 1; }
#fi

# 2. Extract ONLY the first 4 octets (removes the .443 port)
# Input raddr example: 3.146.13.85.443 -> Output _IP: 3.146.13.85
_IP=$(echo "$raddr" | cut -d. -f1-4)

# 3. Validation: If it's not an IP or if it's a local address, skip
[[ ! "$_IP" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]] && return 0
[[ "$_IP" == "127.0.0.1" || "$_IP" == "0.0.0.0" ]] && return 0

# 4. Filter AWS JSON for ranges starting with the same first octet
_OCTET=$(echo "$_IP" | cut -d. -f1)

# We use jq to only return the CIDRs that could possibly match
jq -r --arg oct "$_OCTET." '.prefixes[] | select(.ip_prefix | startswith($oct)) | "\(.ip_prefix) \(.service) (\(.region))"' "$AWS_FILE" | while read -r _CIDR _info; do
    
    # 5. Call your existing script
    # It requires $_IP and $_CIDR. It sets $IS_IN_RANGE
    source ip-in-cidr.sh
    
    if [[ "$IS_IN_RANGE" == "true" ]]; then
        # Print using the sort_key so it appears under the correct process in your main loop
        printf "%s_3.5   AWS: %s\e[K\n" "$sort_key" "$_info"
    fi
done

# Clean up variables to prevent leakage into the next iteration
unset _IP _CIDR _info _OCTET IS_IN_RANGE
