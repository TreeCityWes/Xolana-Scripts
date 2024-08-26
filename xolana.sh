#!/bin/bash

# Define color scheme
BLUE='\033[0;34m'
LIGHT_BLUE='\033[0;94m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
GRAY='\033[0;37m'
YELLOW='\033[0;33m'
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

XOLANA_CONFIG_DIR="$HOME/.config/xolana"
RPC_URL="http://xolana.xen.network:8899"
LOG_FILE="$XOLANA_CONFIG_DIR/xolana_wallet_tool.log"

mkdir -p "$XOLANA_CONFIG_DIR"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
}


function display_menu_header() {
    local title="$1"
    echo -e "\n${BLUE}=== $title ===${NC}\n"
}

function main_menu() {
    show_status_bar
    display_menu_header "MAIN MENU"
    echo -e "${CYAN}1. Wallet Operations${NC}     - Manage your wallet and transactions"
    echo -e "${CYAN}2. Staking Navigator${NC}     - Stake, delegate, and manage validators"
    echo -e "${CYAN}3. Network Insights${NC}      - Explore the Xolana X1 network"
    echo -e "${CYAN}4. About Xolana Testnet${NC}  - Learn about testnet vs mainnet"
    echo -e "${CYAN}5. Exit${NC}                  - Close the Xolana X1 Blockchain Navigator"
    echo
    read -p "$(echo -e "${WHITE}Enter your choice (1-5):${NC} ")" choice

    case $choice in
        1) wallet_operations ;;
        2) staking_navigator ;;
        3) network_insights ;;
        4) explain_testnet ;;
        5) exit_sequence ;;
        *) echo -e "${YELLOW}Invalid choice. Please try again.${NC}" ; sleep 1 ;;
    esac
}

function wallet_operations() {
    while true; do
        show_status_bar
        display_menu_header "WALLET OPERATIONS"
        echo -e "${CYAN}1. View Wallet Details${NC}    - See your wallet address and balance"
        echo -e "${CYAN}2. Send xSOL${NC}              - Transfer xSOL to another address"
        echo -e "${CYAN}3. Airdrop xSOL${NC}           - Request an airdrop of xSOL (testnet only)"
        echo -e "${CYAN}4. Transaction History${NC}    - View your recent transactions"
        echo -e "${CYAN}5. Return to Main Menu${NC}"
        echo
        read -p "$(echo -e "${WHITE}Enter your choice (1-5):${NC} ")" choice

        case $choice in
            1) view_wallet_details ;;
            2) send_xsol ;;
            3) airdrop_xsol ;;
            4) transaction_history ;;
            5) break ;;
            *) echo -e "${YELLOW}Invalid choice. Please try again.${NC}" ; sleep 1 ;;
        esac
    done
}

function view_wallet_details() {
    show_status_bar
    display_menu_header "WALLET DETAILS"
    local address=$(solana address)
    local balance=$(solana balance --url "$RPC_URL")
    echo -e "${WHITE}Wallet Address:${NC} ${LIGHT_BLUE}$address${NC}"
    echo -e "${WHITE}Balance:${NC} ${LIGHT_BLUE}$balance SOL${NC}"
    log "Viewed wallet details for address: $address"
    echo
    read -p "$(echo -e "${GRAY}Press Enter to continue...${NC}")"
}

function send_xsol() {
    show_status_bar
    display_menu_header "SEND xSOL"
    local recipient
    while true; do
        read -p "$(echo -e "${WHITE}Enter recipient address:${NC} ")" recipient
        if validate_address "$recipient"; then
            break
        fi
    done
    local amount
    while true; do
        read -p "$(echo -e "${WHITE}Enter amount of xSOL to send:${NC} ")" amount
        if validate_amount "$amount"; then
            break
        fi
    done
    echo -e "\n${YELLOW}Confirm transfer of $amount xSOL to $recipient${NC}"
    read -p "$(echo -e "${WHITE}Press Enter to confirm or Ctrl+C to cancel...${NC}")"
    output=$(run_solana_command solana transfer --url "$RPC_URL" "$recipient" "$amount")
    if [[ $? -eq 0 ]]; then
        log "Sent $amount xSOL to $recipient"
        echo -e "${GREEN}Successfully sent $amount xSOL to $recipient.${NC}"
    fi
    echo
    read -p "$(echo -e "${GRAY}Press Enter to continue...${NC}")"
}

function airdrop_xsol() {
    show_status_bar
    display_menu_header "AIRDROP xSOL"
    local amount=1
    local address=$(solana address)
    echo -e "\n${YELLOW}Requesting $amount xSOL airdrop to $address${NC}"
    output=$(run_solana_command solana airdrop "$amount" --url "$RPC_URL")
    if [[ $? -eq 0 ]]; then
        log "Airdropped $amount xSOL to address: $address"
        echo -e "${GREEN}Successfully airdropped $amount xSOL to $address.${NC}"
    fi
    echo -e "${CYAN}Note: On Xolana testnet, you can request an airdrop every few minutes.${NC}"
    echo
    read -p "$(echo -e "${GRAY}Press Enter to continue...${NC}")"
}

function transaction_history() {
    show_status_bar
    display_menu_header "TRANSACTION HISTORY"
    local address=$(solana address)
    local limit
    while true; do
        read -p "$(echo -e "${WHITE}Enter the number of recent transactions to display (default 10):${NC} ")" limit
        if [[ -z "$limit" ]]; then
            limit=10
            break
        elif [[ "$limit" =~ ^[0-9]+$ ]]; then
            break
        else
            echo -e "${YELLOW}Please enter a valid number.${NC}"
        fi
    done
    echo -e "\n${CYAN}Fetching the last $limit transactions for address: $address${NC}\n"
    output=$(run_solana_command solana transaction-history --url "$RPC_URL" "$address" --limit "$limit")
    log "Viewed transaction history for address: $address (limit: $limit)"
    echo "$output"
    echo
    read -p "$(echo -e "${GRAY}Press Enter to continue...${NC}")"
}

function staking_navigator() {
    while true; do
        show_status_bar
        display_menu_header "STAKING NAVIGATOR"
        echo -e "${CYAN}1. Create Stake Account${NC}     - Create a new stake account"
        echo -e "${CYAN}2. Delegate Stake${NC}           - Delegate stake to a validator"
        echo -e "${CYAN}3. View Stakes${NC}              - See your current stakes and their status"
        echo -e "${CYAN}4. Deactivate Stake${NC}         - Deactivate a stake account"
        echo -e "${CYAN}5. Withdraw Stake${NC}           - Withdraw from a stake account"
        echo -e "${CYAN}6. Return to Main Menu${NC}"
        echo
        read -p "$(echo -e "${WHITE}Enter your choice (1-6):${NC} ")" choice

        case $choice in
            1) create_stake_account ;;
            2) delegate_stake ;;
            3) view_stakes ;;
            4) deactivate_stake ;;
            5) withdraw_stake ;;
            6) break ;;
            *) echo -e "${YELLOW}Invalid choice. Please try again.${NC}" ; sleep 1 ;;
        esac
    done
}



function create_stake_account() {
    show_status_bar
    display_menu_header "CREATE STAKE ACCOUNT"
    
    local balance=$(solana balance --url "$RPC_URL" | awk '{print $1}')
    if [[ -z "$balance" ]]; then
        echo -e "${RED}Failed to retrieve the balance. Please check your network connection and try again.${NC}"
        return
    fi

    local stake_amount
    while true; do
        read -p "$(echo -e "${WHITE}Enter amount of xSOL to stake (Available: $balance xSOL):${NC} ")" stake_amount
        if [[ "$stake_amount" =~ ^[0-9]+(\.[0-9]+)?$ ]]; then
            if (( $(echo "$stake_amount <= $balance" | bc -l) )); then
                break
            else
                echo -e "${RED}Insufficient funds. Please enter an amount less than or equal to your available balance.${NC}"
            fi
        else
            echo -e "${RED}Invalid amount entered. Please enter a valid number.${NC}"
        fi
    done

    echo -e "${CYAN}Creating new stake account...${NC}"

    local stake_account_keypair="${XOLANA_CONFIG_DIR}/stake-account.json"
    
    # Generate the stake account keypair if it doesn't exist
    if [ ! -f "$stake_account_keypair" ]; then
        solana-keygen new --outfile "$stake_account_keypair"
    fi

    # Create and fund the stake account in one step
    local create_output=$(solana create-stake-account "$stake_account_keypair" "$stake_amount" --url "$RPC_URL" 2>&1)
    local create_status=$?
    echo -e "${YELLOW}Create stake account output:${NC}\n$create_output"
    
    if [[ $create_status -ne 0 ]]; then
        echo -e "${RED}Failed to create the stake account. See output above for details.${NC}"
        return
    fi

    # Extract the stake account public key from the keypair file
    local stake_pubkey=$(solana-keygen pubkey "$stake_account_keypair")
    
    if [[ -z "$stake_pubkey" ]]; then
        echo -e "${RED}Failed to extract stake account public key. Please check the output above.${NC}"
        return
    fi

    echo -e "\n${GREEN}Successfully created stake account: ${WHITE}$stake_pubkey${GREEN} with ${WHITE}$stake_amount xSOL${NC}"
    log "Created stake account: $stake_pubkey with $stake_amount xSOL"

    # Verify the stake account was created and funded
    echo -e "${CYAN}Verifying stake account...${NC}"
    local verify_output=$(solana stake-account "$stake_pubkey" --url "$RPC_URL" 2>&1)
    echo -e "${YELLOW}Stake account details:${NC}\n$verify_output"
    
    if [[ $? -ne 0 ]]; then
        echo -e "${RED}Failed to verify stake account. See output above for details.${NC}"
    else
        echo -e "${GREEN}Stake account verified successfully.${NC}"
    fi

    # Update the balance display
    update_balance

    echo -e "${CYAN}Proceed to delegate your stake to a validator.${NC}"
    read -p "$(echo -e "${GRAY}Press Enter to continue...${NC}")"
}



function update_balance() {
    local new_balance=$(solana balance --url "$RPC_URL" | awk '{print $1}')
    if [[ -n "$new_balance" ]]; then
        balance=$new_balance
    fi
}


function delegate_stake() {
    show_status_bar
    display_menu_header "DELEGATE STAKE"
    
    local wallet_address=$(solana address)
    echo -e "${CYAN}Fetching stake accounts for wallet: $wallet_address${NC}"

    # Fetch all accounts associated with the wallet and filter stake accounts
    local accounts_output=$(solana accounts --url "$RPC_URL" --owner "$wallet_address" --output json)
    
    if [[ -z "$accounts_output" ]]; then
        echo -e "${YELLOW}No accounts found. Please create a stake account first.${NC}"
        read -p "$(echo -e "${GRAY}Press Enter to continue...${NC}")"
        return
    fi

    # Extract public keys of stake accounts
    local stake_accounts=($(echo "$accounts_output" | grep -B 1 '"Stake"' | grep '"pubkey":' | awk -F '"' '{print $4}'))

    if [[ ${#stake_accounts[@]} -eq 0 ]]; then
        echo -e "${YELLOW}No stake accounts found. Please create a stake account first.${NC}"
        read -p "$(echo -e "${GRAY}Press Enter to continue...${NC}")"
        return
    fi

    echo -e "${CYAN}Available Stake Accounts:${NC}"
    for stake_account in "${stake_accounts[@]}"; do
        echo "$stake_account"
    done
    
    local stake_account
    while true; do
        read -p "$(echo -e "${WHITE}Enter the stake account address you want to delegate:${NC} ")" stake_account
        if [[ " ${stake_accounts[*]} " == *" $stake_account "* ]]; then
            break
        else
            echo -e "${RED}Invalid stake account. Please enter one of the listed accounts.${NC}"
        fi
    done

    echo -e "${CYAN}Fetching the list of validators...${NC}"
    local validators=$(solana validators --url "$RPC_URL")
    if [[ $? -ne 0 || -z "$validators" ]]; then
        echo -e "${RED}Failed to fetch validators. Please check your network connection and try again.${NC}"
        return
    fi

    echo -e "${WHITE}Index | Validator Identity | Commission% | Active Stake${NC}"
    echo -e "${CYAN}--------------------------------------------${NC}"
    local index=1
    local validator_list=()
    echo "$validators" | grep -E 'IdentityPubkey|Commission|ActivatedStake' | while read -r line; do
        if [[ $((index % 3)) -eq 1 ]]; then
            identity=$(echo "$line" | awk '{print $2}')
            validator_list+=("$identity")
        elif [[ $((index % 3)) -eq 2 ]]; then
            commission=$(echo "$line" | awk '{print $2}')
        elif [[ $((index % 3)) -eq 0 ]]; then
            stake=$(echo "$line" | awk '{print $2}')
            stake_sol=$(echo "scale=2; $stake / 1000000000" | bc)
            printf "${WHITE}%3d   | %.11s...   | %3d%%         | %.2f SOL${NC}\n" "$((index / 3))" "${validator_list[-1]}" "$commission" "$stake_sol"
        fi
        ((index++))
    done

    local validator_index
    while true; do
        read -p "$(echo -e "${WHITE}Enter the number of the validator you wish to delegate to:${NC} ")" validator_index
        if [[ "$validator_index" =~ ^[0-9]+$ ]] && (( validator_index >= 1 && validator_index <= ${#validator_list[@]} )); then
            break
        else
            echo -e "${RED}Invalid selection. Please enter a number between 1 and ${#validator_list[@]}.${NC}"
        fi
    done

    local validator_pubkey=${validator_list[$((validator_index - 1))]}
    if [[ -z "$validator_pubkey" ]]; then
        echo -e "${RED}Invalid validator selected. Please try again.${NC}"
        return
    fi

    echo -e "\n${YELLOW}Delegating stake account $stake_account to validator $validator_pubkey...${NC}"
    local output=$(solana delegate-stake "$stake_account" "$validator_pubkey" --url "$RPC_URL" 2>&1)
    if [[ $? -eq 0 ]]; then
        echo -e "${GREEN}Successfully delegated stake account to validator: ${WHITE}$validator_pubkey${NC}"
        log "Delegated stake account: $stake_account to validator $validator_pubkey"
    else
        echo -e "${RED}Failed to delegate stake. Error: $output${NC}"
    fi
    read -p "$(echo -e "${GRAY}Press Enter to continue...${NC}")"
}



function view_stakes() {
    show_status_bar
    display_menu_header "VIEW STAKES"
    local wallet_address=$(solana address)
    echo -e "${CYAN}Fetching stakes for wallet: $wallet_address${NC}\n"
    local output=$(solana stakes "$wallet_address" --url "$RPC_URL")
    if [[ -z "$output" || "$output" == *"No stake accounts found"* ]]; then
        echo -e "${YELLOW}No stakes found for this wallet.${NC}"
    else
        echo "$output"
    fi
    log "Viewed stakes for wallet: $wallet_address"
    echo
    read -p "$(echo -e "${GRAY}Press Enter to continue...${NC}")"
}


function show_status_bar() {
    update_balance
    local current_wallet=$(solana address)
    echo -e "\n${BLUE}XOLANA X1 BLOCKCHAIN NAVIGATOR${NC}"
    echo -e "${WHITE}Active Wallet: ${LIGHT_BLUE}${current_wallet:0:12}...${current_wallet: -4}${NC}"
    echo -e "${WHITE}Balance: ${LIGHT_BLUE}$balance SOL${NC}"
    echo -e "${GRAY}$(date '+%Y-%m-%d %H:%M:%S')${NC}"
    echo
}


function deactivate_stake() {
    show_status_bar
    display_menu_header "DEACTIVATE STAKE"
    local stake_account
    while true; do
        read -p "$(echo -e "${WHITE}Enter stake account address to deactivate:${NC} ")" stake_account
        if validate_address "$stake_account"; then
            break
        fi
    done
    output=$(run_solana_command solana deactivate-stake --url "$RPC_URL" "$stake_account")
    if [[ $? -eq 0 ]]; then
        log "Deactivated stake account: $stake_account"
        echo -e "${GREEN}Successfully deactivated stake account: $stake_account${NC}"
    else
        echo -e "${RED}Failed to deactivate stake. Please try again.${NC}"
    fi
    echo
    read -p "$(echo -e "${GRAY}Press Enter to continue...${NC}")"
}

function withdraw_stake() {
    show_status_bar
    display_menu_header "WITHDRAW STAKE"
    local stake_account
    while true; do
        read -p "$(echo -e "${WHITE}Enter stake account address:${NC} ")" stake_account
        if validate_address "$stake_account"; then
            break
        fi
    done
    local withdraw_amount
    while true; do
        read -p "$(echo -e "${WHITE}Enter amount of xSOL to withdraw:${NC} ")" withdraw_amount
        if validate_amount "$withdraw_amount"; then
            break
        fi
    done
    local recipient=$(solana address)
    echo -e "\n${YELLOW}Withdrawing $withdraw_amount xSOL from stake account $stake_account to $recipient${NC}"
    output=$(run_solana_command solana withdraw-stake "$stake_account" "$recipient" "$withdraw_amount" --url "$RPC_URL")
    if [[ $? -eq 0 ]]; then
        echo -e "${GREEN}Successfully withdrew $withdraw_amount xSOL from stake account: $stake_account${NC}"
        log "Withdrew $withdraw_amount xSOL from stake account: $stake_account to $recipient"
    else
        echo -e "${RED}Failed to withdraw stake. Please try again.${NC}"
    fi
    read -p "$(echo -e "${GRAY}Press Enter to continue...${NC}")"
}

function explain_testnet() {
    display_menu_header "ABOUT XOLANA TESTNET"
    echo -e "${CYAN}You are currently using the Xolana testnet, which is a test network for developers and users to experiment without using real funds.${NC}"
    echo -e "${CYAN}Key points about testnets:${NC}"
    echo -e "  ${WHITE}- Tokens on testnet have no real value${NC}"
    echo -e "  ${WHITE}- You can get free tokens through airdrops${NC}"
    echo -e "  ${WHITE}- It's safe to experiment and make mistakes${NC}"
    echo -e "  ${WHITE}- Testnet may be reset periodically, erasing all data${NC}"
    echo -e "${CYAN}Use this environment to learn and test without risk before moving to mainnet.${NC}"
    echo
    read -p "$(echo -e "${GRAY}Press Enter to continue...${NC}")"
}

function network_insights() {
    while true; do
        show_status_bar
        display_menu_header "NETWORK INSIGHTS"
        echo -e "${CYAN}1. Network Status${NC}           - View current network status"
        echo -e "${CYAN}2. Validator List${NC}           - View and analyze validators"
        echo -e "${CYAN}3. Block Explorer${NC}           - Explore blocks and transactions"
        echo -e "${CYAN}4. Network Performance${NC}      - Test network performance"
        echo -e "${CYAN}5. Return to Main Menu${NC}"
        echo
        read -p "$(echo -e "${WHITE}Enter your choice (1-5):${NC} ")" choice

        case $choice in
            1) network_status ;;
            2) enhanced_validator_list ;;
            3) block_explorer ;;
            4) network_performance ;;
            5) break ;;
            *) echo -e "${YELLOW}Invalid choice. Please try again.${NC}" ; sleep 1 ;;
        esac
    done
}

function network_status() {
    show_status_bar
    display_menu_header "NETWORK STATUS"
    echo -e "${CYAN}Fetching network status...${NC}\n"
    
    # Cluster version
    local version=$(run_solana_command solana cluster-version --url "$RPC_URL")
    echo -e "${WHITE}Cluster Version:${NC} $version"
    
    # Total supply
    local supply=$(run_solana_command solana supply --url "$RPC_URL")
    echo -e "${WHITE}Total Supply:${NC} $supply SOL"
    
    # Epoch info
    local epoch_info=$(run_solana_command solana epoch-info --url "$RPC_URL")
    echo -e "${WHITE}Epoch Information:${NC}\n$epoch_info"
    
    # Slot
    local slot=$(run_solana_command solana slot --url "$RPC_URL")
    echo -e "${WHITE}Current Slot:${NC} $slot"
    
    log "Viewed comprehensive network status"
    echo
    read -p "$(echo -e "${GRAY}Press Enter to continue...${NC}")"
}

function enhanced_validator_list() {
    show_status_bar
    display_menu_header "VALIDATOR LIST AND ANALYSIS"
    echo -e "${CYAN}Fetching validator data...${NC}\n"
    
    local validators=$(run_solana_command solana validators --url "$RPC_URL")
    if [[ $? -ne 0 || -z "$validators" ]]; then
        echo -e "${RED}Failed to fetch validators. Please check your network connection and try again.${NC}"
        return
    fi
    
    # Extract total active stake
    local total_active_stake=$(echo "$validators" | grep "ActivatedStake:" | awk '{sum += $2} END {print sum}')
    total_active_stake=$(echo "scale=2; $total_active_stake / 1000000000" | bc)
    echo -e "${WHITE}Total Active Stake:${NC} $total_active_stake SOL"
    
    # Extract number of validators
    local validator_count=$(echo "$validators" | grep -c "IdentityPubkey")
    echo -e "${WHITE}Total Validators:${NC} $validator_count"
    
    # Display top 10 validators by stake
    echo -e "\n${CYAN}Top 10 Validators by Stake:${NC}"
    echo -e "${WHITE}Rank | Validator Identity | Stake (SOL) | Commission%${NC}"
    echo -e "${CYAN}---------------------------------------------------${NC}"
    echo "$validators" | grep -E 'IdentityPubkey|Commission|ActivatedStake' | while read -r line; do
        if [[ $((index % 3)) -eq 1 ]]; then
            identity=$(echo "$line" | awk '{print $2}')
        elif [[ $((index % 3)) -eq 2 ]]; then
            commission=$(echo "$line" | awk '{print $2}')
        elif [[ $((index % 3)) -eq 0 ]]; then
            stake=$(echo "$line" | awk '{print $2}')
            stake_sol=$(echo "scale=2; $stake / 1000000000" | bc)
            if [ $((index / 3)) -le 10 ]; then
                printf "${WHITE}%3d   | %.11s...   | %.2f SOL   | %3d%%${NC}\n" "$((index / 3))" "$identity" "$stake_sol" "$commission"
            fi
        fi
        ((index++))
    done

    log "Viewed enhanced validator list and analysis"
    echo
    read -p "$(echo -e "${GRAY}Press Enter to continue...${NC}")"
}

function network_performance() {
    show_status_bar
    display_menu_header "NETWORK PERFORMANCE"
    echo -e "${CYAN}Testing network performance...${NC}\n"
    
    # TPS (Transactions Per Second)
    echo -e "${WHITE}Transactions Per Second (TPS):${NC}"
    run_solana_command solana transaction-count --url "$RPC_URL" --ws
    
    # Average transaction confirmation time
    echo -e "\n${WHITE}Average Transaction Confirmation Time:${NC}"
    local confirmation_time=$(run_solana_command solana confirm -v --url "$RPC_URL" $(solana transaction-count --url "$RPC_URL") | grep "confirmation time" | awk '{print $NF}')
    echo -e "${confirmation_time} seconds"
    
    # Block production time
    echo -e "\n${WHITE}Block Production Time:${NC}"
    local start_slot=$(run_solana_command solana slot --url "$RPC_URL")
    sleep 10
    local end_slot=$(run_solana_command solana slot --url "$RPC_URL")
    local blocks_produced=$((end_slot - start_slot))
    local block_time=$(echo "scale=2; 10 / $blocks_produced" | bc)
    echo -e "Average block time: ${block_time} seconds"
    echo -e "Blocks produced in 10 seconds: $blocks_produced"
    
    # Network latency
    echo -e "\n${WHITE}Network Latency:${NC}"
    run_solana_command solana ping --url "$RPC_URL" --count 5 --interval 1 --timeout 5
    
    log "Performed network performance tests"
    echo
    read -p "$(echo -e "${GRAY}Press Enter to continue...${NC}")"
}

function block_explorer() {
    show_status_bar
    display_menu_header "BLOCK EXPLORER"
    read -p "$(echo -e "${WHITE}Enter block number or transaction signature:${NC} ")" query
    output=$(run_solana_command solana confirm -v --url "$RPC_URL" "$query")
    if [[ $? -eq 0 ]]; then
        log "Explored block/transaction: $query"
        echo "$output"
    else
        echo -e "${RED}Failed to explore block/transaction. Please try again.${NC}"
    fi
    echo
    read -p "$(echo -e "${GRAY}Press Enter to continue...${NC}")"
}

function exit_sequence() {
    echo -e "\n${CYAN}Disconnecting from the Xolana X1 network...${NC}"
    log "User exited the Xolana X1 Blockchain Navigator"
    sleep 2
    echo -e "${GREEN}Thank you for using the Xolana X1 Blockchain Navigator. Goodbye!${NC}"
    exit 0
}

function handle_error() {
    echo -e "${RED}An error occurred: $1${NC}"
    log "ERROR: $1"
    read -p "$(echo -e "${GRAY}Press Enter to continue...${NC}")"
}

function run_solana_command() {
    local command="$1"
    shift
    output=$(${command} "$@" 2>&1)
    exit_code=$?
    if [ $exit_code -ne 0 ]; then
        handle_error "Failed to execute: $command $*\nError: $output"
        return $exit_code
    fi
    echo "$output"
}

function check_solana_cli() {
    if ! command -v solana &> /dev/null; then
        echo -e "${RED}Solana CLI is not installed. Please install it and try again.${NC}"
        echo -e "${CYAN}Visit https://docs.solana.com/cli/install-solana-cli-tools for installation instructions.${NC}"
        exit 1
    fi

    ensure_xolana_testnet
}

function ensure_xolana_testnet() {
    local current_url=$(solana config get | grep 'RPC URL:' | awk '{print $NF}')
    if [ "$current_url" != "$RPC_URL" ]; then
        echo -e "${YELLOW}Switching to Xolana testnet...${NC}"
        solana config set --url "$RPC_URL"
        echo -e "${GREEN}Successfully switched to Xolana testnet.${NC}"
    else
        echo -e "${GREEN}Already connected to Xolana testnet.${NC}"
    fi
}

function verify_connection() {
    if ! solana cluster-version --url "$RPC_URL" &> /dev/null; then
        echo -e "${RED}Unable to connect to Xolana X1 network. Please check your internet connection and try again.${NC}"
        exit 1
    fi
}

function validate_address() {
    local address="$1"
    if [[ ! $address =~ ^[1-9A-HJ-NP-Za-km-z]{32,44}$ ]]; then
        echo -e "${RED}Invalid address format.${NC}"
        return 1
    fi
    return 0
}

function validate_amount() {
    local amount="$1"
    if ! [[ $amount =~ ^[0-9]+(\.[0-9]+)?$ ]]; then
        echo -e "${RED}Invalid amount format. Please enter a valid number.${NC}"
        return 1
    fi
    return 0
}

check_solana_cli
verify_connection
echo -e "${LIGHT_BLUE}"
cat << "EOF"
                                           
 XOLANA X1 BLOCKCHAIN NAVIGATOR
EOF
echo -e "${NC}"
echo -e "${WHITE}Welcome to the Xolana X1 Blockchain Navigator - Testnet Edition${NC}"
echo -e "${GRAY}Initializing secure connection to the Xolana X1 testnet...${NC}"
sleep 2

while true; do
    main_menu
done
