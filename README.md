# XPort EVM Cross-Chain Token Transfer Demo

This project demonstrates how to use the XPort EVM protocol to implement cross-chain token transfer functionality. By deploying TokenHome contracts on the source chain and TokenRemote contracts on the destination chain, it enables secure token transfers from the source chain to the destination chain.

## Environment Setup

### 1. Install Foundry

First, ensure your system has the Foundry toolkit installed. If not, execute the following commands:

```bash
curl -L https://foundry.paradigm.xyz | bash
foundryup
```

After installation, verify it was successful:

```bash
forge --version
cast --version
```

### 2. Clone the Repository

```bash
git clone <repository_url>
cd xport-evm-usage-demo
```

> Note: Replace `<repository_url>` with the actual repository address

### 3. Install Dependencies

```bash
forge install
```

### 4. Compile Contracts

```bash
forge build
```

## Important Configuration Notes

### Wanchain Testnet Special Configuration

When using the Wanchain testnet, pay special attention to the following configurations:

1. **Transaction Parameters**: Must add the following parameters, otherwise estimated gas will cause transactions to get stuck:
   - `forge script` command: add `--legacy --with-gas-price 4000000000`
   - `cast send` command: add `--legacy --gas-price 4000000000`

2. **EVM Version**: In `foundry.toml`, EVM version must be configured as `london` or earlier:
   ```toml
   evm_version = "london"
   ```

### Avalanche Configuration

When deploying on Avalanche, EVM version needs to be configured as `shanghai`:
   ```toml
   evm_version = "shanghai"
   ```

### Other EVM Chain Configuration

Other EVM-compatible chains have no special requirements; configure according to actual needs.

## Step-by-Step Guide

The following 14 steps will guide you through the complete cross-chain token transfer process. Each step depends on the output of the previous step, so please execute in strict order and update the corresponding variables in deployment scripts promptly.

### Step 1: Deploy Mock Token (Source Chain)
Deploy the test Mock ERC20 token on the source chain (e.g., Wanchain testnet).

```bash
forge script script/DeployMockToken.s.sol --rpc-url https://gwan-ssl.wandevs.org:46891 --private-key YOUR_PRIVATE_KEY --broadcast --legacy --with-gas-price 4000000000
```

**Command Parameter Details**:
- `forge script`: Foundry's script execution command for deploying and interacting with smart contracts
- `script/DeployMockToken.s.sol`: Path to the deployment script file to execute
- `--rpc-url https://gwan-ssl.wandevs.org:46891`: Specifies the blockchain network RPC node address (Wanchain testnet here)
- `--private-key YOUR_PRIVATE_KEY`: Private key for signing transactions (replace with your actual private key)
- `--broadcast`: Broadcasts the transaction to the network (without this parameter, only simulation occurs)
- `--legacy`: Uses traditional transaction format (non-EIP-1559), required for Wanchain testnet
- `--with-gas-price 4000000000`: Sets fixed gas price to 4 Gwei to prevent transaction getting stuck

**After execution**: Record the output Mock Token contract address for use in subsequent steps.

### Step 2: Get Test Tokens
Request test tokens from the newly deployed Mock Token contract.

```bash
cast send MOCK_TOKEN_ADDRESS "mint(address,uint256)" YOUR_WALLET_ADDRESS 100ether --rpc-url https://gwan-ssl.wandevs.org:46891 --private-key YOUR_PRIVATE_KEY --legacy --gas-price 4000000000
```

**Command Parameter Details**:
- `cast send`: Foundry's transaction sending command for calling contract functions
- `MOCK_TOKEN_ADDRESS`: Target contract address (Mock Token address deployed in Step 1)
- `"mint(address,uint256)"`: Contract function signature to call, here it's the token minting function
- `YOUR_WALLET_ADDRESS`: Wallet address to receive tokens
- `100ether`: Number of tokens to mint (100 tokens, using ether unit to represent 10^18 precision)
- `--rpc-url https://gwan-ssl.wandevs.org:46891`: Connected blockchain network RPC node
- `--private-key YOUR_PRIVATE_KEY`: Private key for signing transactions
- `--legacy`: Uses traditional transaction format, required for Wanchain testnet
- `--gas-price 4000000000`: Sets gas price to 4 Gwei

**Need to replace**:
- `MOCK_TOKEN_ADDRESS`: Mock Token address deployed in Step 1
- `YOUR_WALLET_ADDRESS`: Your wallet address

### Step 3: Check Token Balance
Verify if tokens have been successfully received.

```bash
cast call MOCK_TOKEN_ADDRESS "balanceOf(address)" YOUR_WALLET_ADDRESS --rpc-url https://gwan-ssl.wandevs.org:46891
```

**Need to replace**:
- `MOCK_TOKEN_ADDRESS`: Mock Token address deployed in Step 1
- `YOUR_WALLET_ADDRESS`: Your wallet address

### Step 4: Deploy TokenHome Contract (Source Chain)
Deploy the TokenHome contract on the source chain for managing cross-chain token sending.

```bash
forge script script/DeployTokenHome.s.sol --rpc-url https://gwan-ssl.wandevs.org:46891 --private-key YOUR_PRIVATE_KEY --broadcast --legacy --with-gas-price 4000000000
```

**Command Parameter Details**:
- `script/DeployTokenHome.s.sol`: TokenHome contract deployment script
- Other parameters are the same as Step 1

**Before execution**: Ensure the following variables in `DeployTokenHome.s.sol` are updated:
- `wmbGateway`: WMB Gateway contract address (pre-configured for testnet, can be modified as needed)
- `token`: Set to the Mock Token address deployed in Step 1

**Need to replace**:
- `YOUR_PRIVATE_KEY`: Your wallet private key

**After execution**: Record the output TokenHome contract address and update it in the `homeTokenAddress` variable in `DeployTokenRemote.s.sol` script.

### Step 5: Deploy TokenRemote Contract (Destination Chain)
Deploy the TokenRemote contract on the destination chain (e.g., Ethereum Sepolia) for receiving cross-chain tokens.

```bash
forge script script/DeployTokenRemote.s.sol --rpc-url https://ethereum-sepolia-rpc.publicnode.com --private-key YOUR_PRIVATE_KEY --broadcast
```

**Command Parameter Details**:
- `script/DeployTokenRemote.s.sol`: TokenRemote contract deployment script
- `--rpc-url https://ethereum-sepolia-rpc.publicnode.com`: Destination chain RPC node address (Ethereum Sepolia here)
- Other parameters are the same as Step 1, but `--legacy` and `--with-gas-price` are not needed (unless destination chain requires them)

**Before execution**: Ensure the following variables in `DeployTokenRemote.s.sol` are updated:
- `homeTokenAddress`: Set to the TokenHome address obtained in Step 4
- `remoteChainId`: Set to the source chain's chain ID (e.g., 999 for Wanchain testnet)

**Need to replace**:
- `YOUR_PRIVATE_KEY`: Your wallet private key

**After execution**: Record the output TokenRemote contract address.

### Step 6: Check Initial Cross-Chain Message Status
Query the status of cross-chain messages to confirm the system is working properly.

```bash
curl -XGET https://testnet.wanscan.org/api/cc/msg/tx\?sendTxHash\=0x76bb15b56143f7e4e760c5adf02b144b17a12727e296ebd4f212d27e72851c7a | jq
```

**Command Parameter Details**:
- `curl -XGET`: Uses GET method to send HTTP request
- `https://testnet.wanscan.org/api/cc/msg/tx`: Wanchain cross-chain message query API endpoint
- `sendTxHash=0x76bb15b56143f7e4e760c5adf02b144b17a12727e296ebd4f212d27e72851c7a`: Transaction hash to query
- `| jq`: Uses jq tool to format JSON response (optional)

**Need to replace**:
- `0x76bb15b56143f7e4e760c5adf02b144b17a12727e296ebd4f212d27e72851c7a`: Replace with the actual transaction hash from Step 5 (TokenRemote deployment transaction)

> If `jq` command is not installed, you can use curl directly:
> ```bash
> curl -XGET "https://testnet.wanscan.org/api/cc/msg/tx?sendTxHash=0x76bb15b56143f7e4e760c5adf02b144b17a12727e296ebd4f212d27e72851c7a"
> ```

### Step 7: Approve TokenHome to Use Tokens
Authorize the TokenHome contract to transfer your tokens.

```bash
cast send MOCK_TOKEN_ADDRESS "approve(address,uint256)" TOKEN_HOME_ADDRESS 100ether --rpc-url https://gwan-ssl.wandevs.org:46891 --private-key YOUR_PRIVATE_KEY --legacy --gas-price 4000000000
```

**Need to replace**:
- `MOCK_TOKEN_ADDRESS`: Mock Token address
- `TOKEN_HOME_ADDRESS`: TokenHome address deployed in Step 4

### Step 8: Execute Cross-Chain Token Transfer
Transfer tokens from the source chain to the destination chain.

```bash
cast send TOKEN_HOME_ADDRESS "crossTo(address,uint256)" REMOTE_TOKEN_ADDRESS 100ether --rpc-url https://gwan-ssl.wandevs.org:46891 --private-key YOUR_PRIVATE_KEY --legacy --gas-price 4000000000 --value 0.01 ether
```

**Need to replace**:
- `TOKEN_HOME_ADDRESS`: TokenHome contract address
- `REMOTE_TOKEN_ADDRESS`: TokenRemote address deployed in Step 5

### Step 9: Check Cross-Chain Transaction Status
Monitor the processing status of the cross-chain transaction.

```bash
curl -XGET https://testnet.wanscan.org/api/cc/msg/tx\?sendTxHash\=TRANSACTION_HASH | jq
```

**Need to replace**: `TRANSACTION_HASH` with the actual transaction hash from Step 8 (cross-chain token transfer transaction)

### Step 10: Check Destination Chain Token Balance
Confirm tokens have successfully arrived on the destination chain.

```bash
cast call REMOTE_TOKEN_ADDRESS "balanceOf(address)" YOUR_WALLET_ADDRESS --rpc-url https://ethereum-sepolia-rpc.publicnode.com
```

### Step 11: Burn Tokens on Destination Chain
Burn tokens on the destination chain to prepare for cross-chain return.

```bash
cast send REMOTE_TOKEN_ADDRESS "burn(address,uint256)" YOUR_WALLET_ADDRESS 100ether --rpc-url https://ethereum-sepolia-rpc.publicnode.com --private-key YOUR_PRIVATE_KEY --legacy --gas-price 4000000000
```

### Step 12: Check Burn Cross-Chain Status
Monitor the cross-chain return status after token burning.

```bash
curl -XGET https://testnet.wanscan.org/api/cc/msg/tx\?sendTxHash\=BURN_TRANSACTION_HASH | jq
```

**Need to replace**: `BURN_TRANSACTION_HASH` with the actual transaction hash from Step 11 (token burn transaction)

### Step 13: Check Source Chain Token Balance
Confirm tokens have successfully returned to the source chain.

```bash
cast call MOCK_TOKEN_ADDRESS "balanceOf(address)" YOUR_WALLET_ADDRESS --rpc-url https://gwan-ssl.wandevs.org:46891
```

### Step 14: Check Destination Chain Final Balance
Verify tokens have been correctly burned on the destination chain.

```bash
cast call REMOTE_TOKEN_ADDRESS "balanceOf(address)" YOUR_WALLET_ADDRESS --rpc-url https://ethereum-sepolia-rpc.publicnode.com
```

## Important Notes

1. **Variable Updates**: After each step, update the output results to corresponding variables in the next step
2. **Gas Price**: Must use fixed gas price (4000000000) on Wanchain testnet
3. **Transaction Confirmation**: Wait for transaction confirmation before proceeding to the next step
4. **Balance Verification**: Verify relevant balances after completing key steps to ensure successful operations

## Troubleshooting

- If transactions are pending for a long time, check if `--legacy` and gas price parameters are used correctly
- If contract deployment fails, confirm EVM version configuration is correct
- If cross-chain fails, query specific error information through wanscan API

## Support

For issues, get help through the following methods:
- Check transaction hash details on corresponding blockchain explorers
- Use curl commands to query wanscan API for cross-chain status
- Check return values and error messages for each step
