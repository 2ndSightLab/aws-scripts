#!/bin/bash 

# mac version - monitor network connections

# --- USER CHOICE SECTION ---
clear
echo "Network Monitor Setup"
echo "----------------------"
echo "1) TCP only"
echo "2) UDP only"
echo "3) ICMP only"
echo "4) IPv4 only"
echo "5) IPv6 only"
echo "6) ALL TRAFFIC"
printf "Choice [1-6]: "
read -r choice

# Set grep filters based on choice
case "$choice" in
    1) p_filter="tcp" ;;
    2) p_filter="udp" ;;
    3) p_filter="icmp" ;;
    4) p_filter="tcp4|udp4|icmp4|inet " ;; # Space after inet prevents false positives
    5) p_filter="tcp6|udp6|icmp6|inet6" ;;
    *) p_filter="." ;;
esac

# Trigger sudo early
echo "Starting... Please enter your password."
sudo -v
printf "\e[?25l"
stty -echo
trap 'printf "\e[?25h"; stty echo; clear; exit' INT TERM EXIT

decode_flags() {
    local hex_val=$(echo "$1" | grep -oE '[0-9a-fA-F]{2,8}$')
    local hex_tail="${hex_val: -2}"
    case "$hex_tail" in
        10) echo "ACK" ;; 08) echo "PSH" ;; 18) echo "PSH,ACK" ;;
        02) echo "SYN" ;; 04) echo "RST" ;; 01) echo "FIN" ;;
        12) echo "SYN,ACK" ;; 11) echo "FIN,ACK" ;; *)  echo "-" ;;
    esac
}

clear

while true; do
    # Keep sudo alive
    sudo -n true 2>/dev/null || sudo -v

    # Gather data
    output=$(sudo netstat -anv | grep -iE "$p_filter" | while read -r line; do
        
        # Skip only completely idle listeners (*.* to *.*)
        [[ "$line" == *" *.* "*" *.* "* ]] && continue

        proto=$(echo "$line" | awk '{print $1}')
        laddr=$(echo "$line" | awk '{print $4}')
        raddr=$(echo "$line" | awk '{print $5}')
        lport=$(echo "$laddr" | awk -F. '{print $NF}')
        rport=$(echo "$raddr" | awk -F. '{print $NF}')
        
        if [[ "$rport" =~ ^[0-9]+$ ]] && [ "$lport" -gt "$rport" ]; then dir="OUT"; else dir="IN"; fi

        proc_chunk=$(echo "$line" | grep -oE '[^[:space:]]+:[0-9]+' | head -n1)
        if [[ -n "$proc_chunk" ]]; then
            raw_pid=$(echo "$proc_chunk" | cut -d: -f2)
            hex_raw=$(echo "$line" | awk -v search="$proc_chunk" '{for(i=1;i<=NF;i++) if($i==search) print $(i+1)}')
            child_path=$(ps -p "$raw_pid" -o comm= 2>/dev/null)
            ppid=$(ps -p "$raw_pid" -o ppid= 2>/dev/null | tr -d ' ')
            parent_path=$(ps -p "${ppid:-0}" -o comm= 2>/dev/null || echo "-")
 
        else
            raw_pid="0"; ppid="0"; hex_raw="00000000"; dir="SYS"; child_path="-"; parent_path="-"
        fi

        [[ "$proto" == *"tcp"* ]] && flags=$(decode_flags "$hex_raw") || flags=$(echo "$proto" | tr '[:lower:]' '[:upper:]')
        
        sort_key="${raw_pid}_${lport}_${raddr}"

        printf "%s_1 %-6s %-20s %-20s %-10s %-7s %-7s %-5s\e[K\n" "$sort_key" "$proto" "$laddr" "$raddr" "$flags" "$raw_pid" "$ppid" "$dir"
        printf "%s_2   PARENT PROCESS: %s\e[K\n" "$sort_key" "$parent_path"
        if [ "$child_path" != "$parent_path" ] && [ "$child_path" != "-" ]; then
            printf "%s_3   CHILD PROCESS:  %s\e[K\n" "$sort_key" "$child_path"
        fi

        source aws-ip-info.sh 

        printf "%s_4 \e[K\n" "$sort_key"
    done | sort -u | awk '
        BEGIN { toggle = 0; last_grp = "" }
        {
            split($1, parts, "_")
            current_grp = parts[1] "_" parts[2] "_" parts[3]
            if (current_grp != last_grp) { toggle = 1 - toggle; last_grp = current_grp }
            line = substr($0, index($0, " ") + 1)
            if (toggle == 1) printf "\033[2m%s\033[22m\n", line; else print line
        }')

    printf "\e[H"
    printf "Network Monitor - $(date +%H:%M:%S) [Mode: $choice]\e[K\n"
    printf "====================================================================================================\e[K\n"
    printf "\e[1;34m%-6s %-20s %-20s %-10s %-7s %-7s %-5s\e[0m\e[K\n" "PROTO" "LOCAL_ADDR" "REMOTE_ADDR" "FLAGS" "PID" "PPID" "DIR"
    printf "====================================================================================================\e[K\n"
    
    printf "%s\e[J" "$output"
    sleep 5
done
