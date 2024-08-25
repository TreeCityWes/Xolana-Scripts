# X1 Xolana - Python Wallet Utility for Xolana CLI

Welcome to the **X1 Xolana Wallet Address Utility**! This tool is designed to provide seamless interaction with the X1 - Xolana blockchain. You can manage your wallet, check balances, review transaction details, and much more, all through an intuitive and easy-to-use interface.

## Features

- **Check Your Balance**: View your current SOL balance and recent transactions.
- **Check Other Balance**: Check the balance of any Solana wallet.
- **Send xSOL**: Transfer xSOL to another wallet.
- **View Transaction Info**: Retrieve detailed information about a specific transaction.
- **Review Validators**: View information about current validators.
- **View Gossip Nodes**: List gossip nodes in the network.
- **Network Testing**: Perform network pings to test connectivity.
- **Config Details**: Display keypair and configuration details.

## Requirements

- Python 3.x
- `solana-cli` installed and configured
- Dependencies listed in `requirements.txt`

## Installation

1. **Clone the Repository**:
    ```sh
    git clone https://github.com/TreeCityWes/Py-Xolana.git
    cd Py-Xolana
    ```

2. **Install Dependencies**:
    ```sh
    pip install -r requirements.txt
    ```

3. **Install Solana CLI**:
    ```sh
    sh -c "$(curl -sSfL https://release.solana.com/stable/install)"
    ```

## Usage

1. **Run the Utility**:
    ```sh
    python xolana.py
    ```

2. **Menu Options**:
    - `[1] Check Your Balance`
    - `[2] Check Other Balance`
    - `[3] Send xSOL`
    - `[4] View Transaction Info`
    - `[5] Review Validators`
    - `[6] View Gossip Nodes`
    - `[7] Network Testing`
    - `[8] Config Details`
    - `[9] Exit`

## Configuration

- **Keypair**: The tool uses the default keypair from the `solana-cli` configuration. Ensure it is properly set up, or specify the keypair file path in `xolana.py`.

## Example

To check your balance:

```sh
python xolana.py

Select option [1] from the menu to check your balance and recent transactions.

To send xSOL:

python xolana.py

Select option [3], then enter the recipient’s public key and the amount of xSOL to transfer.

Contact
Developer: TreeCityWes.eth
Wallet Address: 8bXf8Rg3u4Prz71LgKR5mpa7aMe2F4cSKYYRctmqro6x
Enjoy using the X1 Xolana Wallet Address Utility!
