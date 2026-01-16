
list_actions() {
    local SERVICE="$1"
    local PROFILE="$2"
    
    if [[ -z "$SERVICE" || -z "$PROFILE" ]]; then
        echo "Usage: list_actions <service> <profile>"
        return 1
    fi
    
    aws $SERVICE help --profile "$PROFILE" --region us-east-1 --no-cli-pager --color off 2>/dev/null | \
    sed 's/\x1b\[[0-9;]*m//g' | \
    grep -A 100 "AVAILABLE COMMANDS" | \
    grep -o '[a-z][a-z-]*$' | \
    sed 's/-\([a-z]\)/\U\1/g' | \
    sed 's/^./\U&/' | \
    sed "s/^/$SERVICE:/" | \
    sort -u
}

