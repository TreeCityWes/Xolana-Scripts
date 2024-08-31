#!/bin/bash

# Define your Xolana WebSocket URL
WS_URL="ws://xolana.xen.network:8900"

# ANSI color codes (Smooth green palette)
BRIGHT_GREEN='\033[1;32m'
DARK_GREEN='\033[0;32m'
LIGHT_GREEN='\033[1;92m'
DIM_GREEN='\033[2;32m'
WHITE='\033[1;37m'
NC='\033[0m' # No Color

# Description
DESCRIPTION="This script monitors transactions on the X1 Testnet for the Xolana project.
It displays the most active programs, logs relevant transaction details, and updates in real-time."

# Function to send the subscription request
send_subscription() {
    echo '{"jsonrpc":"2.0","id":1,"method":"logsSubscribe","params":["all",{"commitment":"confirmed"}]}'
}

# Initialize variables
declare -A program_counts
count=0
slot=0
log_lines=()
max_log_lines=15
chart_height=12
term_height=$(tput lines)
term_width=$(tput cols)
log_area_height=$((term_height - chart_height - 9))  # Reserved space for logs
log_content_max_length=$((term_width - 30))  # Max length for log content display

# Function to update the display
update_display() {
    # Update program stats
    tput cup 5 0

    # Calculate total interactions and percentages
    local total_interactions=$(echo "${program_counts[@]}" | tr ' ' '+' | bc)

    # Sort programs by percentage and display
    (for prog in "${!program_counts[@]}"; do
        local count=${program_counts[$prog]}
        local percent=$(echo "scale=0; $count * 100 / $total_interactions" | bc)
        printf "%s,%d,%d\n" "$prog" "$count" "$percent"
    done) | sort -t',' -k3 -rn | head -n 10 | while IFS=',' read -r prog count percent; do
        # Print the table without the graph column
        printf "%-68s | %12d | %10d%%\n" "$prog" "$count" "$percent"
    done

    # Update slot number
    tput cup 2 0
    echo -e "${DIM_GREEN}Current Slot Number: $slot${NC}"

    # Move cursor to start of log area
    tput cup $((chart_height + 7)) 0

    # Display logs with double spacing
    for ((i = 0; i < log_area_height && i < ${#log_lines[@]}; i++)); do
        tput cup $((chart_height + 8 + i)) 0
        echo -e "${log_lines[i]}"
    done

    # Clear remaining lines in log area
    tput ed
}

# Draw the initial layout
draw_layout() {
    clear
    echo -e "${BRIGHT_GREEN}Xolana Transaction Monitoring by TreeCityWes.eth${NC}"
    echo -e "${DARK_GREEN}Monitoring transactions on X1 Testnet at $WS_URL${NC}"
    echo -e "${DIM_GREEN}Current Slot Number: $slot${NC}"
    echo "======================================================================="
    printf "${BRIGHT_GREEN}%-68s | %12s | %11s${NC}\n" "Program ID" "Interactions" "Percentage"
    echo "======================================================================="
    for i in {1..10}; do
        echo
    done
    echo "======================================================================="
    echo -e "${DARK_GREEN}Recent Transaction Logs:${NC}"
    echo "======================================================================="
    for i in $(seq 1 $log_area_height); do
        echo
    done
}

# Function to add a log entry
add_log_entry() {
    local slot_local=$1
    local program_id=$2
    local signature=$3
    local log_content=$4
    local timestamp=$(date +'%H:%M:%S')

    # Format log entry with green colors
    local log_output="${DIM_GREEN}$timestamp${NC} | Slot: $slot_local | ${BRIGHT_GREEN}${program_id}${NC} | Sig: ${BRIGHT_GREEN}${signature}${NC}"
    
    # Truncate log content if it exceeds the max length
    if [ ${#log_content} -gt $log_content_max_length ]; then
        log_content="${log_content:0:$((log_content_max_length - 3))}..."
    fi
    
    local log_content_display="${DARK_GREEN}Logs:${NC} $log_content"

    # Add to log lines array with spacing
    log_lines=("$log_output" "$log_content_display" "" "${log_lines[@]}")

    # Trim log lines to fit screen
    if [ ${#log_lines[@]} -gt $((log_area_height * 3)) ]; then
        log_lines=("${log_lines[@]:0:$((log_area_height * 3))}")
    fi
}

# Main processing loop
process_transactions() {
    while read -r line; do
        # Check if line is empty or null
        if [[ -z "$line" ]]; then
            continue
        fi

        ((count++))

        # Extract signature, slot, and logs from the message
        slot=$(echo "$line" | jq -r '.params.result.context.slot // empty' 2>/dev/null)
        signature=$(echo "$line" | jq -r '.params.result.value.signature // empty' 2>/dev/null)
        logs=$(echo "$line" | jq -r '.params.result.value.logs[] // empty' 2>/dev/null)

        # Skip processing if any critical field is empty
        if [[ -z "$slot" || -z "$signature" || -z "$logs" ]]; then
            continue
        fi

        # Extract program ID and log content
        program_id=$(echo "$logs" | grep -oP '(?<=Program )([^ ]+)' | head -n1)
        log_content=$(echo "$logs" | grep -oP 'Program log: \K.*' | tr '\n' ' ' | head -n1)

        if [[ -z "$program_id" || -z "$log_content" ]]; then
            continue
        fi

        ((program_counts[$program_id]++))
        add_log_entry "$slot" "$program_id" "$signature" "$log_content"

        # Update display every transaction
        update_display
    done
}

# Trap SIGINT to clear the screen on exit
trap 'tput cnorm; echo -e "\033[2J\033[H"; exit 0' SIGINT

# Hide cursor
tput civis

# Start the script
draw_layout
echo "Connecting to WebSocket at $WS_URL..."
(send_subscription; cat) | websocat "$WS_URL" | process_transactions
