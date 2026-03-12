#!/bin/bash
# Fetch AWS IP ranges and filter by service/region or lookup by IP

DATA=$(curl -s https://ip-ranges.amazonaws.com/ip-ranges.json)

echo "1. Search by Service + Region"
echo "2. Search by IP Address"
read -p "Select an option: " MODE

if [[ "$MODE" == "2" ]]; then
  read -p "Enter IP address: " IP
  echo ""
  echo "=== Results for $IP ==="
  echo "$DATA" | jq -r --arg ip "$IP" '
    .prefixes[] as $p |
    ($p.ip_prefix | split("/")) as [$net, $mask] |
    ($net | split(".") | map(tonumber)) as $n |
    ($ip | split(".") | map(tonumber)) as $i |
    (pow(2;32) - pow(2; 32-($mask|tonumber))) as $m |
    (($n[0]*16777216 + $n[1]*65536 + $n[2]*256 + $n[3]) as $nint |
     ($i[0]*16777216 + $i[1]*65536 + $i[2]*256 + $i[3]) as $iint |
     select(($nint - ($nint % pow(2; 32-($mask|tonumber)))) ==
            ($iint - ($iint % pow(2; 32-($mask|tonumber)))))) |
    "\($p.ip_prefix)\t\($p.service)\t\($p.region)\t\($p.network_border_group)"
  ' | sort -u | column -t -s$'\t'
else
  SERVICES=($(echo "$DATA" | jq -r '.prefixes[].service' | sort -u))
  echo ""
  echo "Available AWS Services:"
  for i in "${!SERVICES[@]}"; do
    echo "  $((i+1)). ${SERVICES[$i]}"
  done

  read -p "Select a service (number): " choice
  SERVICE="${SERVICES[$((choice-1))]}"
  if [[ -z "$SERVICE" ]]; then
    echo "Invalid selection." && exit 1
  fi

  read -p "Enter region (leave blank for all): " REGION

  if [[ -n "$REGION" ]]; then
    HEADER="$SERVICE - $REGION"
    FILTER=".prefixes[] | select(.service==\"$SERVICE\" and .region==\"$REGION\") | .ip_prefix"
  else
    HEADER="$SERVICE"
    FILTER=".prefixes[] | select(.service==\"$SERVICE\") | .ip_prefix"
  fi

  echo ""
  echo "=== $HEADER ==="
  echo "$DATA" | jq -r "$FILTER" | sort -t. -k1,1n -k2,2n -k3,3n -k4,4n
fi
