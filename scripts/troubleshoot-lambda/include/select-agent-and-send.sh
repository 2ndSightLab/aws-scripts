echo ""
echo "========================================"
echo "       Collected Logs"
echo "========================================"
echo ""
echo "${LOGS_OUTPUT}"

echo ""
echo "========================================"
echo "       Sending to Kiro CLI for Analysis"
echo "========================================"
echo ""

# --- Prompt for Kiro CLI agent ---
# Discover available agents from workspace, user, and sibling project directories
REPO_ROOT=$(cd "${SCRIPT_DIR}/../.." && pwd)
AVAILABLE_AGENTS=()
AGENT_DIRS=()
for AGENT_DIR in "${REPO_ROOT}/.kiro/agents" "${HOME}/.kiro/agents"; do
    if [ -d "${AGENT_DIR}" ]; then
        for AGENT_FILE in "${AGENT_DIR}"/*.json; do
            [ -f "${AGENT_FILE}" ] || continue
            ANAME=$(basename "${AGENT_FILE}" .json)
            AVAILABLE_AGENTS+=("${ANAME}")
            AGENT_DIRS+=("${AGENT_DIR%/.kiro/agents}")
        done
    fi
done

# Search sibling project directories for agent configurations
PARENT_DIR=$(cd "${REPO_ROOT}/.." && pwd)
for SIBLING in "${PARENT_DIR}"/*/; do
    [ -d "${SIBLING}" ] || continue
    SIBLING_AGENT_DIR="${SIBLING}.kiro/agents"
    [ -d "${SIBLING_AGENT_DIR}" ] || continue
    for AGENT_FILE in "${SIBLING_AGENT_DIR}"/*.json; do
        [ -f "${AGENT_FILE}" ] || continue
        ANAME=$(basename "${AGENT_FILE}" .json)
        # Skip duplicates
        DUPLICATE=0
        for EXISTING in "${AVAILABLE_AGENTS[@]}"; do
            if [ "${EXISTING}" = "${ANAME}" ]; then DUPLICATE=1; break; fi
        done
        [ "${DUPLICATE}" -eq 1 ] && continue
        AVAILABLE_AGENTS+=("${ANAME}")
        AGENT_DIRS+=("${SIBLING%/}")
    done
done

if [ ${#AVAILABLE_AGENTS[@]} -eq 0 ]; then
    echo "ERROR: No Kiro CLI agents found" >&2
    exit 1
fi

# select_agent: Display agents, filter by letter input, select by number input
AGENT_DISPLAY=("${AVAILABLE_AGENTS[@]}")
while true; do
    echo ""
    echo "Available agents:"
    for i in "${!AGENT_DISPLAY[@]}"; do
        echo "  $((i+1))) ${AGENT_DISPLAY[$i]}"
    done
    read -r -p "Select agent [number] or type to filter: " AGENT_INPUT
    if [[ "${AGENT_INPUT}" =~ ^[0-9]+$ ]]; then
        if [ "${AGENT_INPUT}" -ge 1 ] && [ "${AGENT_INPUT}" -le ${#AGENT_DISPLAY[@]} ]; then
            # Find the index in the full array
            SELECTED_NAME="${AGENT_DISPLAY[$((AGENT_INPUT-1))]}"
            for i in "${!AVAILABLE_AGENTS[@]}"; do
                if [ "${AVAILABLE_AGENTS[$i]}" = "${SELECTED_NAME}" ]; then
                    AGENT_NUM=$((i+1))
                    break
                fi
            done
            break
        fi
        echo "Invalid selection."
    elif [[ "${AGENT_INPUT}" =~ ^[a-zA-Z] ]]; then
        AGENT_FILTERED=()
        for a in "${AVAILABLE_AGENTS[@]}"; do
            if [[ "${a,,}" == *"${AGENT_INPUT,,}"* ]]; then
                AGENT_FILTERED+=("$a")
            fi
        done
        if [ ${#AGENT_FILTERED[@]} -eq 0 ]; then
            echo "No agents match '${AGENT_INPUT}'. Showing all."
            AGENT_DISPLAY=("${AVAILABLE_AGENTS[@]}")
        else
            AGENT_DISPLAY=("${AGENT_FILTERED[@]}")
        fi
    else
        echo "Invalid input."
    fi
done
KIRO_AGENT="${AVAILABLE_AGENTS[$((AGENT_NUM-1))]}"
KIRO_AGENT_DIR="${AGENT_DIRS[$((AGENT_NUM-1))]}"
echo "Using agent: ${KIRO_AGENT}"

# --- Build the prompt and show it before sending ---
KIRO_PROMPT="Analyze the following AWS Lambda logs and configuration for function '${FUNCTION_NAME}'. Identify all errors, warnings, and issues. For each issue found, explain the root cause and recommend a specific solution.

${LOGS_OUTPUT}"

echo ""
echo "========================================"
echo "       Prompt to be sent to Kiro CLI"
echo "========================================"
echo ""
echo "${KIRO_PROMPT}"
echo ""
echo "========================================"
echo ""

echo "Add instructions to prefix the analysis (press Enter on empty line to skip/finish):"
USER_PREFIX=""
LINE=""
while IFS= read -r -p "> " LINE; do
    [ -z "${LINE}" ] && break
    if [ -n "${USER_PREFIX}" ]; then
        USER_PREFIX+=$'\n'
    fi
    USER_PREFIX+="${LINE}"
    LINE=""
done
if [ -n "${USER_PREFIX}" ]; then
    KIRO_PROMPT="${USER_PREFIX}

${KIRO_PROMPT}"
fi

read -r -p "Confirm sending the above prompt? (y/n): " CONFIRM_SEND
if [ "${CONFIRM_SEND}" != "y" ]; then echo "Exiting."; exit 0; fi

if [ "${KIRO_AGENT_DIR}" != "${REPO_ROOT}" ]; then
    echo "Switching to agent project directory: ${KIRO_AGENT_DIR}"
    cd "${KIRO_AGENT_DIR}"
fi

kiro-cli chat --agent "${KIRO_AGENT}" "${KIRO_PROMPT}"
