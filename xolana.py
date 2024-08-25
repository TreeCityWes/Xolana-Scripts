import os
import json
import subprocess
import requests
from solders.keypair import Keypair
from solders.pubkey import Pubkey
from solders.transaction import VersionedTransaction
from solders.system_program import TransferParams, transfer
from solders.message import MessageV0
from solders.rpc.requests import GetBalance, GetLatestBlockhash
from solders.hash import Hash
from base58 import b58encode
from rich.console import Console
from rich.prompt import Prompt
from rich.panel import Panel
from rich.style import Style
from rich import box
from rich.table import Table
import time
from time import sleep 
console = Console()

# Constants
LAMPORTS_PER_SOL = 10**9  # 1 SOL = 1 billion lamports
RPC_URL = "http://xolana.xen.network:8899"  # Xolana X1 testnet RPC URL

# Styles
green_style = Style(color="green", bold=True)
dim_green_style = Style(color="green", dim=True)
bright_green_style = Style(color="bright_green")

# Helper function to send RPC requests
def send_rpc_request(method, params):
    payload = {
        "jsonrpc": "2.0",
        "method": method,
        "params": params,
        "id": 1
    }
    try:
        response = requests.post(RPC_URL, json=payload, timeout=10)
        response.raise_for_status()
        return response.json()
    except requests.exceptions.RequestException as e:
        console.print(f"[bold red]Error sending RPC request: {e}[/bold red]")
        return None

# Helper function to get default keypair path from solana-cli config
def get_default_keypair_path():
    try:
        result = subprocess.run(["solana", "config", "get"], capture_output=True, text=True)
        for line in result.stdout.splitlines():
            if "Keypair Path:" in line:
                return line.split(":", 1)[1].strip()
    except Exception as e:
        console.print(f"[bold red]Failed to get default keypair path: {e}[/bold red]")
        return None
    
def splash_screen():
    art = """
[bold bright_green]                                                  
XXXXXXX       XXXXXXX  1111111          [bright_white]Welcome to [/bright_white][bold bright_green]X1 Xolana[/bold bright_green][bright_white] - Wallet Address Utility[/bright_white]
X:::::X       X:::::X 1::::::1          
X:::::X       X:::::X1:::::::1          [bright_white]This tool is designed to provide seamless interaction[/bright_white]
X::::::X     X::::::X111:::::1          [bright_white]with the [/bright_white][bold bright_green]X1 - Xolana blockchain[/bold bright_green][bright_white]. Manage your wallet, check balances,[/bright_white]
XXX:::::X   X:::::XXX   1::::1          [bright_white]review transaction details, and much more,[/bright_white]
   X:::::X X:::::X      1::::1          [bright_white]all through an intuitive and easy-to-use interface.[/bright_white]
    X:::::X:::::X       1::::1          
     X:::::::::X        1::::l          
     X:::::::::X        1::::l          [bold bright_cyan]Developed by [/bold bright_cyan][bold bright_green]TreeCityWes.eth[/bold bright_green]
    X:::::X:::::X       1::::l           [bright_white]Wallet Address:[/bright_white] [bold bright_cyan]8bXf8Rg3u4Prz71LgKR5mpa7aMe2F4cSKYYRctmqro6x[/bold bright_cyan]
   X:::::X X:::::X      1::::l          
XXX:::::X   X:::::XXX   1::::l          
X::::::X     X::::::X111::::::111       
X:::::X       X:::::X1::::::::::1       
X:::::X       X:::::X1::::::::::1       
XXXXXXX       XXXXXXX111111111111       
[/bold bright_green]                                                 
    """

    console.print(Panel(
        art.strip(),
        border_style="bright_green",
    ))


# Menu Display
def display_menu():
    options = [
        "[1] Check Your Balance",
        "[2] Check Other Balance",
        "[3] Send xSOL",
        "[4] View Transaction Info",
        "[5] Review Validators",
        "[6] View Gossip Nodes",
        "[7] Network Testing",
        "[8] Config Details",
        "[9] Exit",
    ]
    console.print(Panel("\n".join(options), title="Main Menu", border_style="green", box=box.ROUNDED))

# Load Keypair from Config
def load_keypair(file_path):
    try:
        with open(file_path, "r") as keyfile:
            secret_key = json.load(keyfile)
        return Keypair.from_bytes(bytes(secret_key))
    except Exception as e:
        console.print(f"[bold red]Failed to load keypair: {e}[/bold red]")
        return None

# Convert Lamports to SOL
def lamports_to_sol(lamports):
    return lamports / LAMPORTS_PER_SOL

# Check Balance (Self or Others)
def check_balance(keypair=None, address=None):
    if address:
        try:
            pubkey = Pubkey.from_string(address)
        except ValueError:
            console.print(f"[bold red]Invalid public key: {address}[/bold red]")
            return
    elif keypair:
        pubkey = keypair.pubkey()
    else:
        console.print(f"[bold red]No keypair loaded![/bold red]")
        return
    
    # Get SOL balance
    response_json = send_rpc_request("getBalance", [str(pubkey)])
    
    # Retrieve recent transactions (e.g., last 5)
    transaction_history_json = send_rpc_request("getConfirmedSignaturesForAddress2", [str(pubkey), {"limit": 5}])

    if response_json and 'result' in response_json and 'value' in response_json['result']:
        balance = response_json['result']['value']
        sol_balance = lamports_to_sol(balance)
        
        # Recent Transactions
        transactions = transaction_history_json['result']
        
        # Display information
        info_lines = [
            f"Balance for {pubkey}: [bright_green]{sol_balance:.9f} xSOL[/]",
            "",
            "Recent Transactions:",
        ]

        for tx in transactions:
            info_lines.append(f"  - Signature: {tx['signature']}, Slot: {tx['slot']}")

        console.print(Panel("\n".join(info_lines), border_style="green"))
        
    else:
        console.print(Panel(f"[bold red]Failed to retrieve balance. Response: {response_json}[/bold red]", border_style="red"))

def transfer_sol(keypair):
    recipient = Prompt.ask(f"[{dim_green_style}]Enter recipient's public key[/]")
    amount = float(Prompt.ask(f"[{dim_green_style}]Enter amount of SOL to send[/]"))

    try:
        recipient_pubkey = Pubkey.from_string(recipient)
        ix = transfer(TransferParams(
            from_pubkey=keypair.pubkey(),
            to_pubkey=recipient_pubkey,
            lamports=int(amount * LAMPORTS_PER_SOL)
        ))
        
        blockhash_response_json = send_rpc_request("getLatestBlockhash", [])
        
        if blockhash_response_json and 'result' in blockhash_response_json and 'value' in blockhash_response_json['result']:
            blockhash_str = blockhash_response_json['result']['value']['blockhash']
            blockhash = Hash.from_string(blockhash_str)
        else:
            raise Exception(f"Failed to get blockhash. Response: {blockhash_response_json}")
        
        msg = MessageV0.try_compile(
            payer=keypair.pubkey(),
            instructions=[ix],
            address_lookup_table_accounts=[],
            recent_blockhash=blockhash,
        )
        
        tx = VersionedTransaction(msg, [keypair])
        serialized_tx = bytes(tx)
        encoded_tx = b58encode(serialized_tx).decode('utf-8')
        
        result_json = send_rpc_request("sendTransaction", [encoded_tx])
        
        if result_json and 'result' in result_json:
            signature = result_json['result']
            console.print(Panel(f"Transaction sent!\nSignature: {signature}", border_style="green"))


            # Wait for 5 seconds before checking the transaction status
            console.print(Panel(f"Waiting for 10 seconds before checking transaction status for\n{signature[:80]}...", border_style="yellow"))
            time.sleep(15)

            # Check the transaction status after 5 seconds
            view_transaction_info(signature)
        else:
            console.print(Panel(f"[bold red]Failed to send transaction. Response: {result_json}[/bold red]", border_style="red"))
    except Exception as e:
        console.print(Panel(f"[bold red]Failed to send transaction: {e}[/bold red]", border_style="red"))


# View Transaction Info
def view_transaction_info(signature=None):
    if not signature:
        signature = Prompt.ask(f"[{dim_green_style}]Enter transaction signature[/]")
    
    try:
        response_json = send_rpc_request("getTransaction", [
            signature, 
            {"encoding": "jsonParsed", "maxSupportedTransactionVersion": 0}
        ])
        
        if response_json is None:
            console.print(Panel("[bold red]Failed to retrieve transaction data. The RPC request failed.[/bold red]", border_style="red"))
            return

        if 'result' not in response_json or response_json['result'] is None:
            console.print(Panel("[bold red]Transaction not found or not confirmed. Please check the signature and try again.[/bold red]", border_style="red"))
            return

        tx_data = response_json['result']
        
        info = [
            f"Signature: {signature}",
            f"Slot: {tx_data['slot']}",
            f"Block Time: {tx_data.get('blockTime', 'N/A')}",
            f"Recent Blockhash: {tx_data['transaction']['message']['recentBlockhash']}",
            "",
            "Accounts:",
        ]
        
        for account in tx_data['transaction']['message']['accountKeys']:
            info.append(f"  - {account['pubkey']} (Writable: {account['writable']}, Signer: {account['signer']})")
        
        info.append("\nInstructions:")
        for idx, instruction in enumerate(tx_data['transaction']['message']['instructions']):
            info.append(f"  Instruction {idx + 1}:")
            info.append(f"    Program: {instruction['program']}")
            info.append(f"    Program ID: {instruction['programId']}")
            if 'parsed' in instruction:
                info.append(f"    Type: {instruction['parsed']['type']}")
                for key, value in instruction['parsed']['info'].items():
                    info.append(f"      {key}: {value}")
            else:
                info.append(f"    Data: {instruction['data']}")
        
        if 'meta' in tx_data and tx_data['meta'] is not None:
            meta = tx_data['meta']
            if meta.get('err'):
                info.append(f"\n[bold red]Error:[/] {meta['err']}")
            else:
                info.append(f"\n[bold green]Transaction successful[/]")
            
            info.append(f"\nFee: {lamports_to_sol(meta['fee'])} SOL")
            
            if 'preBalances' in meta and 'postBalances' in meta:
                info.append("\nBalance Changes:")
                for i, (pre, post) in enumerate(zip(meta['preBalances'], meta['postBalances'])):
                    change = post - pre
                    if change != 0:
                        info.append(f"  Account {i}: {lamports_to_sol(change):+.9f} SOL")
            
            if 'rewards' in meta and meta['rewards']:
                info.append("\nRewards:")
                for reward in meta['rewards']:
                    info.append(f"  {reward['pubkey']}: {lamports_to_sol(reward['lamports']):+.9f} SOL (Type: {reward['rewardType']})")
        
        info.append(f"\nStatus: {tx_data.get('confirmationStatus', 'Unknown').capitalize()}")
        
        console.print(Panel("\n".join(info), title="Transaction Info", border_style="green"))
        
    except Exception as e:
        console.print(Panel(f"[bold red]An error occurred while retrieving transaction info: {e}[/bold red]", border_style="red"))

def review_validators():
    response_json = send_rpc_request("getVoteAccounts", [])
    
    if response_json and 'result' in response_json:
        validators = response_json['result']['current']
        
        if not validators:
            console.print(Panel("[bold red]No validators found.[/bold red]", border_style="red"))
            return
        
        table = Table(title="Validators", box=box.ROUNDED)
        table.add_column("Validator Identity", style="bold cyan")
        table.add_column("Commission (%)", style="bold magenta")
        table.add_column("Activated Stake (SOL)", style="bold green")
        table.add_column("Last Vote", style="bold yellow")
        table.add_column("Uptime (Epoch)", style="bold blue")

        for validator in validators:
            identity_pubkey = validator.get('nodePubkey', 'N/A')
            commission = str(validator.get('commission', 'N/A'))
            activated_stake = lamports_to_sol(validator.get('activatedStake', 0))
            last_vote = str(validator.get('lastVote', 'N/A'))
            uptime = str(validator.get('epochCredits', [['N/A']])[-1][1])  # Gets the last entry of epoch credits
            
            table.add_row(identity_pubkey, commission, f"{activated_stake:.2f}", last_vote, uptime)

        console.print(Panel(table, title="Current Validators", border_style="green"))
    else:
        console.print(Panel(f"[bold red]Failed to retrieve validators. Response: {response_json}[/bold red]", border_style="red"))

# Helper function to convert lamports to SOL
def lamports_to_sol(lamports):
    return lamports / 10**9
def gossip_nodes():
    response_json = send_rpc_request("getClusterNodes", [])
    
    if response_json and 'result' in response_json:
        nodes = response_json['result']
        
        table = Table(title="Gossip Nodes", box=box.ROUNDED)
        table.add_column("Node", style="bold green")
        table.add_column("IP Address")
        table.add_column("TPU Port")
        
        for node in nodes:
            table.add_row(node['pubkey'], node.get('gossip', 'N/A'), str(node.get('tpu', 'N/A')))
        
        console.print(Panel(table, title="Gossip Nodes", border_style="green"))
    else:
        console.print(Panel(f"[bold red]Failed to retrieve gossip nodes. Response: {response_json}[/bold red]", border_style="red"))
from time import sleep

def network_testing():
    console.print(Panel("[bold green]Network Test Running...[/bold green]", border_style="green"))

    # Initialize a list to store each ping result for the final summary table
    ping_results = []

    try:
        for seq in range(5):  # Running the ping 5 times
            result = subprocess.run(["solana", "ping", "--count", "1"], capture_output=True, text=True)
            if result.returncode == 0:
                # Extract time from the result
                output_lines = result.stdout.strip().splitlines()
                time_line = next((line for line in output_lines if "time=" in line), "")

                time_taken = time_line.split("time=")[1].strip() if time_line else "N/A"

                # Print each ping test result immediately without the signature
                console.print(f"[bright_green]Ping Test {seq + 1} complete: {time_taken}[/]")

                # Store the results for the final table
                ping_results.append((f"Ping Test - {seq + 1}", "✅ Success", time_taken))
            else:
                console.print(f"[bold red]Ping Test {seq + 1} failed[/bold red]")
                ping_results.append((f"Ping Test - {seq + 1}", "❌ Failed", "N/A"))
            
            sleep(1)  # Adding a delay between pings

        # Create a table to display all results (without the signature column)
        table = Table(title="Network Ping Test Results", box=box.ROUNDED, border_style="green")
        table.add_column("Ping Test", style="bold cyan")
        table.add_column("Status", style="bold green")
        table.add_column("Time (ms)", style="bold yellow")

        for result in ping_results:
            table.add_row(result[0], result[1], result[2])

        console.print(table)
        console.print(Panel("[bold green]Network Test Completed[/bold green]", border_style="green"))

    except Exception as e:
        console.print(Panel(f"[bold red]An error occurred during the network test: {e}[/bold red]", border_style="red"))

def network_details(keypair):
    console.print(Panel("[bright_green]Network & Wallet Information[/]", border_style="green"))

    try:
        # Wallet address and balance
        wallet_address = keypair.pubkey()
        response_json = send_rpc_request("getBalance", [str(wallet_address)])
        wallet_balance = lamports_to_sol(response_json['result']['value']) if response_json and 'result' in response_json else "Failed to retrieve balance."

        # RPC URL
        rpc_url = RPC_URL

        # RPC Version
        try:
            version_result = subprocess.run(["solana", "--version"], capture_output=True, text=True)
            rpc_version = version_result.stdout.strip().split(" ")[1]
        except Exception as e:
            rpc_version = f"Failed to retrieve version. Error: {e}"

        # RPC Health
        try:
            health_result = subprocess.run(["solana", "health"], capture_output=True, text=True)
            rpc_health = health_result.stdout.strip()
        except Exception as e:
            rpc_health = f"Failed to retrieve health. Error: {e}"

        # Current Slot
        try:
            slot_result = subprocess.run(["solana", "block", "get"], capture_output=True, text=True)
            current_slot = slot_result.stdout.strip().split()[1]
        except Exception as e:
            current_slot = f"Failed to retrieve current slot. Error: {e}"

        # Current Block Time
        try:
            block_time_result = subprocess.run(["solana", "block-time", current_slot], capture_output=True, text=True)
            current_block_time = block_time_result.stdout.strip()
        except Exception as e:
            current_block_time = f"Failed to retrieve block time. Error: {e}"

        # Display the results
        table = Table(title="Network & Wallet Information", box=box.ROUNDED, border_style="green")
        table.add_column("Metric", style="bold cyan")
        table.add_column("Value", style="bold white")

        table.add_row("Wallet Address", str(wallet_address))
        table.add_row("Wallet Balance (xSOL)", f"{wallet_balance:.9f}" if isinstance(wallet_balance, float) else wallet_balance)
        table.add_row("RPC URL", rpc_url)
        table.add_row("RPC Version", rpc_version)
        table.add_row("Current Block Time", current_block_time)

        console.print(table)

    except Exception as e:
        console.print(Panel(f"[bold red]An error occurred while retrieving network details: {e}[/bold red]", border_style="red"))


def main():
    splash_screen()
    keypair_file_path = get_default_keypair_path()

    if not keypair_file_path:
        console.print("[bold red]Default keypair not found. Exiting.[/bold red]")
        return

    keypair = load_keypair(keypair_file_path)

    if not keypair:
        console.print("[bold red]Failed to load keypair. Exiting.[/bold red]")
        return

    while True:
        display_menu()
        choice = Prompt.ask(f"[{dim_green_style}]Enter your choice[/]")

        if choice == '1':
            check_balance(keypair=keypair)
        elif choice == '2':
            address = Prompt.ask(f"[{dim_green_style}]Enter public key to check[/]")
            check_balance(address=address)
        elif choice == '3':
            transfer_sol(keypair)
        elif choice == '4':
            view_transaction_info()
        elif choice == '5':
            review_validators()
        elif choice == '6':
            gossip_nodes()
        elif choice == '7':
            network_testing()
        elif choice == '8':
            network_details(keypair)  # Pass the keypair here
        elif choice == '9':
            console.print("[bold green]Exiting...[/bold green]")
            break
        else:
            console.print("[bold red]Invalid option. Please try again.[/bold red]")

if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        console.print("\n[bold yellow]Program interrupted. Exiting...[/bold yellow]")
    except Exception as e:
        console.print(f"[bold red]An unexpected error occurred: {e}[/bold red]")
        console.print("[bold yellow]Please report this issue to the developers.[/bold yellow]")
    finally:
        console.print("[bold green]Thank you for using X1:Xolana Wallet Manager![/bold green]")
