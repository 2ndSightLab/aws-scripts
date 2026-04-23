# --- Check custom domain resolution ---
FUNCTION_URL=$(echo "${URL_CONFIG}" | grep -o '"FunctionUrl"[[:space:]]*:[[:space:]]*"[^"]*"' | sed 's/.*"\(http[^"]*\)"/\1/')
if [ -n "${FUNCTION_URL}" ]; then
    FUNCTION_URL_HOST=$(echo "${FUNCTION_URL}" | sed 's|https\?://||' | sed 's|/.*||')
    echo ""
    read -r -p "Enter custom domain for this Lambda (press Enter to skip): " CUSTOM_DOMAIN
    if [ -n "${CUSTOM_DOMAIN}" ]; then
        echo "Checking DNS resolution for ${CUSTOM_DOMAIN}..."
        DIG_RESULT=$(dig +short "${CUSTOM_DOMAIN}" 2>&1)
        if [ -z "${DIG_RESULT}" ]; then
            PROBLEMS_OUTPUT+="PROBLEM: Custom domain '${CUSTOM_DOMAIN}' does not resolve. DNS is not configured or propagation has not completed.
FIX: Verify a DNS record (CNAME, A alias, or CloudFront distribution) exists for '${CUSTOM_DOMAIN}' pointing to '${FUNCTION_URL_HOST}' or an intermediary (e.g., CloudFront).

"
            PROBLEMS_FOUND=$((PROBLEMS_FOUND+1))
            LOGS_OUTPUT+="=== CUSTOM DOMAIN DNS ===
Domain: ${CUSTOM_DOMAIN}
Resolution: FAILED - no DNS records found

"
        else
            LOGS_OUTPUT+="=== CUSTOM DOMAIN DNS ===
Domain: ${CUSTOM_DOMAIN}
Resolves to:
${DIG_RESULT}
Lambda Function URL host: ${FUNCTION_URL_HOST}

"
            echo "  ${CUSTOM_DOMAIN} resolves to:"
            echo "  ${DIG_RESULT}"
            # Check if it resolves to the function URL host
            if echo "${DIG_RESULT}" | grep -q "${FUNCTION_URL_HOST}"; then
                echo "  DNS points directly to Lambda Function URL."
            else
                echo "  DNS does not point directly to Lambda Function URL (may route via CloudFront or other proxy)."
            fi
        fi
    fi
fi
