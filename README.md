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
git clone https://github.com/wandevs/xport-evm-usage-demo.git
cd xport-evm-usage-demo
```

> Note: Replace `https://github.com/wandevs/xport-evm-usage-demo.git` with the actual repository address

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

Output example:

```bash
[⠊] Compiling...
No files changed, compilation skipped
Warning: EIP-3855 is not supported in one or more of the RPCs used.
Unsupported Chain IDs: 999.
Contracts deployed with a Solidity version equal or higher than 0.8.20 might not work properly.
For more information, please see https://eips.ethereum.org/EIPS/eip-3855
Script ran successfully.

== Logs ==
  MockERC20 deployed to: 0x6BFAf71e3170f3Ae9129810262C2d189128c795f

## Setting up 1 EVM.

==========================

Chain 999

Estimated gas price: 4 gwei

Estimated total gas used for script: 1223556

Estimated amount required: 0.004894224 HYPE

==========================

##### hyperliquid
✅  [Success] Hash: 0xfbd0903741579819a92645e72dfae697191acddcc9c81c2a81ebef087d031db7
Contract Address: 0x6BFAf71e3170f3Ae9129810262C2d189128c795f
Block: 38853473
Paid: 0.003764788 HYPE (941197 gas * 4 gwei)

✅ Sequence #1 on hyperliquid | Total Paid: 0.003764788 HYPE (941197 gas * avg 4 gwei)
                                                                                                                                                                                            

==========================

ONCHAIN EXECUTION COMPLETE & SUCCESSFUL.

Transactions saved to: /Users/molin/workspace/temp/xport-evm-usage-demo/broadcast/DeployMockToken.s.sol/999/run-latest.json

Sensitive values saved to: /Users/molin/workspace/temp/xport-evm-usage-demo/cache/DeployMockToken.s.sol/999/run-latest.json

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

Output example:

```bash

blockHash            0x43f24745cdee5fc064b0dce013868137c85d8e3820f7b8bf2afe24c5f95356e2
blockNumber          38853501
contractAddress      
cumulativeGasUsed    68947
effectiveGasPrice    4000000000
from                 0x2fb4D46372Ea1748ec3c29Bd2C7B536019DF5200
gasUsed              68947
logs                 [{"address":"0x6bfaf71e3170f3ae9129810262c2d189128c795f","topics":["0xddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef","0x0000000000000000000000000000000000000000000000000000000000000000","0x0000000000000000000000002fb4d46372ea1748ec3c29bd2c7b536019df5200"],"data":"0x0000000000000000000000000000000000000000000000056bc75e2d63100000","blockHash":"0x43f24745cdee5fc064b0dce013868137c85d8e3820f7b8bf2afe24c5f95356e2","blockNumber":"0x250db7d","transactionHash":"0x24e737c97a502f2cdd7fd8cf4d432f2d717b420e26876153e86da9cc628326f3","transactionIndex":"0x0","logIndex":"0x0","removed":false}]
logsBloom            0x00000010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000200000000000000000000008000000000000000000000000000000000000000000000000020000000000000000000800000000000000000000000010000000000000000000000000100000000000000000000000000000000000000000000000000000000000000000000000000002000000000000000000000000000000000000000002000000000000800000000000000000000000000000000000000020000002000000000000000000000000000000000000000000000000000000000000
root                 
status               1 (success)
transactionHash      0x24e737c97a502f2cdd7fd8cf4d432f2d717b420e26876153e86da9cc628326f3
transactionIndex     0
type                 255
blobGasPrice         
blobGasUsed          
to                   0x6BFAf71e3170f3Ae9129810262C2d189128c795f
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
cast call MOCK_TOKEN_ADDRESS "balanceOf(address)" YOUR_WALLET_ADDRESS --rpc-url https://gwan-ssl.wandevs.org:46891 | cast fw
```

Output example:

```bash
100.000000000000000000
```

**Need to replace**:
- `MOCK_TOKEN_ADDRESS`: Mock Token address deployed in Step 1
- `YOUR_WALLET_ADDRESS`: Your wallet address

### Step 4: Deploy TokenHome Contract (Source Chain)
Deploy the TokenHome contract on the source chain for managing cross-chain token sending.

**Before execution**: Ensure the following variables in `DeployTokenHome.s.sol` are updated:
- `wmbGateway`: WMB Gateway contract address (pre-configured for testnet, can be modified as needed)
- `token`: Set to the Mock Token address deployed in Step 1

```bash
forge script script/DeployTokenHome.s.sol --rpc-url https://gwan-ssl.wandevs.org:46891 --private-key YOUR_PRIVATE_KEY --broadcast --legacy --with-gas-price 4000000000
```

Output example:

```bash
[⠊] Compiling...
[⠒] Compiling 1 files with Solc 0.8.25
[⠑] Solc 0.8.25 finished in 446.87ms
Compiler run successful!
Warning: EIP-3855 is not supported in one or more of the RPCs used.
Unsupported Chain IDs: 999.
Contracts deployed with a Solidity version equal or higher than 0.8.20 might not work properly.
For more information, please see https://eips.ethereum.org/EIPS/eip-3855
Script ran successfully.

== Logs ==
  Erc20TokenHome deployed to: 0xc75DFEBF42e2ca4f9F9b90F980B7a484946f94b5

## Setting up 1 EVM.

==========================

Chain 999

Estimated gas price: 4 gwei

Estimated total gas used for script: 1563555

Estimated amount required: 0.00625422 HYPE

==========================

##### hyperliquid
✅  [Success] Hash: 0xa6df5ccfb39c205fddf6e32b64966f8f4d84a3ad27397b46b5c80a51b59d2203
Contract Address: 0xc75DFEBF42e2ca4f9F9b90F980B7a484946f94b5
Block: 38853610
Paid: 0.00481094 HYPE (1202735 gas * 4 gwei)

✅ Sequence #1 on hyperliquid | Total Paid: 0.00481094 HYPE (1202735 gas * avg 4 gwei)
                                                                                                                                                                                            

==========================

ONCHAIN EXECUTION COMPLETE & SUCCESSFUL.

Transactions saved to: /Users/molin/workspace/temp/xport-evm-usage-demo/broadcast/DeployTokenHome.s.sol/999/run-latest.json

Sensitive values saved to: /Users/molin/workspace/temp/xport-evm-usage-demo/cache/DeployTokenHome.s.sol/999/run-latest.json

```

**Command Parameter Details**:
- `script/DeployTokenHome.s.sol`: TokenHome contract deployment script
- Other parameters are the same as Step 1

**Need to replace**:
- `YOUR_PRIVATE_KEY`: Your wallet private key

**After execution**: Record the output TokenHome contract address and update it in the `homeTokenAddress` variable in `DeployTokenRemote.s.sol` script.

### Step 5: Deploy TokenRemote Contract (Destination Chain)
Deploy the TokenRemote contract on the destination chain (e.g., Ethereum Sepolia) for receiving cross-chain tokens.

**Before execution**: Ensure the following variables in `DeployTokenRemote.s.sol` are updated:
- `homeTokenAddress`: Set to the TokenHome address obtained in Step 4
- `remoteChainId`: Set to the source chain's chain ID (e.g., 2153201998 for Wanchain, could be query from: https://docs.wanchain.org/products/xport/xport-developer-handbook#id-3.-supported-blockchains or https://github.com/wanchain/message-bridge-contracts )

```bash
forge script script/DeployTokenRemote.s.sol --rpc-url https://ethereum-sepolia-rpc.publicnode.com --private-key YOUR_PRIVATE_KEY --broadcast
```

Output example:

```bash
[⠊] Compiling...
[⠔] Compiling 1 files with Solc 0.8.25
[⠑] Solc 0.8.25 finished in 447.47ms
Compiler run successful!
Script ran successfully.

== Logs ==
  Erc20TokenRemote deployed to: 0xd6fF848B81DB0D8cBB35FEd91346554133cF8A73

## Setting up 1 EVM.

==========================

Chain 11155111

Estimated gas price: 0.001019514 gwei

Estimated total gas used for script: 2432069

Estimated amount required: 0.000002479528394466 ETH

==========================

##### sepolia
✅  [Success] Hash: 0xd30fca67bb23a778f16e10d7f4616262270370924c39673287ad30e942b21914
Contract Address: 0xd6fF848B81DB0D8cBB35FEd91346554133cF8A73
Block: 9261392
Paid: 0.000001887406304979 ETH (1871493 gas * 0.001008503 gwei)

✅ Sequence #1 on sepolia | Total Paid: 0.000001887406304979 ETH (1871493 gas * avg 0.001008503 gwei)
                                                                                                                                                                                            

==========================

ONCHAIN EXECUTION COMPLETE & SUCCESSFUL.

Transactions saved to: /Users/molin/workspace/temp/xport-evm-usage-demo/broadcast/DeployTokenRemote.s.sol/11155111/run-latest.json

Sensitive values saved to: /Users/molin/workspace/temp/xport-evm-usage-demo/cache/DeployTokenRemote.s.sol/11155111/run-latest.json

```

**Command Parameter Details**:
- `script/DeployTokenRemote.s.sol`: TokenRemote contract deployment script
- `--rpc-url https://ethereum-sepolia-rpc.publicnode.com`: Destination chain RPC node address (Ethereum Sepolia here)
- Other parameters are the same as Step 1, but `--legacy` and `--with-gas-price` are not needed (unless destination chain requires them)


**Need to replace**:
- `YOUR_PRIVATE_KEY`: Your wallet private key

**After execution**: Record the output TokenRemote contract address.

### Step 6: Check Initial Cross-Chain Message Status
Query the status of cross-chain messages to confirm the system is working properly.

```bash
curl -XGET https://testnet.wanscan.org/api/cc/msg/tx?sendTxHash=0x76bb15b56143f7e4e760c5adf02b144b17a12727e296ebd4f212d27e72851c7a | jq
```

Output example:
```bash
curl -XGET https://testnet.wanscan.org/api/cc/msg/tx\?sendTxHash\=0xd30fca67bb23a778f16e10d7f4616262270370924c39673287ad30e942b21914 | jq
  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
100   744  100   744    0     0    341      0  0:00:02  0:00:02 --:--:--   341
[
  {
    "timestamp": 1758614304,
    "msgs": [
      {
        "to": "0xc75dfebf42e2ca4f9f9b90f980b7a484946f94b5",
        "data": "0x0000000000000000000000000000000000000000000000000000000000000001"
      }
    ],
    "receiveTimestamp": 1758614449,
    "fee": {
      "value": "0.000000051796",
      "unit": "ETH",
      "price": "4208.46"
    },
    "cost": {
      "value": "0.000384154",
      "unit": "WAN",
      "price": "0.098428"
    },
    "msgId": "0x5950e9dec5de7b8fa3a81b665943a9afdfc6f5496c97bc5720e8dbde27eef3ee",
    "fromChain": "ETH",
    "toChain": "WAN",
    "from": "0x2fb4d46372ea1748ec3c29bd2c7b536019df5200",
    "sendTxHash": "0xd30fca67bb23a778f16e10d7f4616262270370924c39673287ad30e942b21914",
    "status": "Success",
    "receiveTxHash": "0x53b67a995040803ee36b94a608ea658b2a7036fc25e5cbad1563b1884d846b70",
    "smg": "0x000000000000000000000000000000000000000000746573746e65745f303830"
  }
]
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

If you can see the status is Success, it means the cross-chain message has been successfully processed.

Wait until the status is Success before proceeding to the next step.

### Step 7: Approve TokenHome to Use Tokens
Authorize the TokenHome contract to transfer your tokens.

```bash
cast send MOCK_TOKEN_ADDRESS "approve(address,uint256)" TOKEN_HOME_ADDRESS 100ether --rpc-url https://gwan-ssl.wandevs.org:46891 --private-key YOUR_PRIVATE_KEY --legacy --gas-price 4000000000
```

Output example:
```bash
blockHash            0x197fd82a434ea766457863fc77de9dd21600a9ad82aa87c80a38b80f11d0ae2b
blockNumber          38853686
contractAddress      
cumulativeGasUsed    46964
effectiveGasPrice    4000000000
from                 0x2fb4D46372Ea1748ec3c29Bd2C7B536019DF5200
gasUsed              46964
logs                 [{"address":"0x6bfaf71e3170f3ae9129810262c2d189128c795f","topics":["0x8c5be1e5ebec7d5bd14f71427d1e84f3dd0314c0f7b2291e5b200ac8c7c3b925","0x0000000000000000000000002fb4d46372ea1748ec3c29bd2c7b536019df5200","0x000000000000000000000000c75dfebf42e2ca4f9f9b90f980b7a484946f94b5"],"data":"0x0000000000000000000000000000000000000000000000056bc75e2d63100000","blockHash":"0x197fd82a434ea766457863fc77de9dd21600a9ad82aa87c80a38b80f11d0ae2b","blockNumber":"0x250dc36","transactionHash":"0x4f1f7417667c743d28d4492df9d1c3f7a6bc76c05b67eb257372f8f6f632ae0d","transactionIndex":"0x0","logIndex":"0x0","removed":false}]
logsBloom            0x00000010000040000000000000000000000000000000000000000000000000000000000000000000010000000000000000000000000000000000001000200000200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000100000000000000000000000000000000000000000000000020000000000000000000000000002000000000000000000000000000000000000000000000000000000800000000000000000000000000000000000000000000012000000000000000000000000000000000000000000000000000000000000
root                 
status               1 (success)
transactionHash      0x4f1f7417667c743d28d4492df9d1c3f7a6bc76c05b67eb257372f8f6f632ae0d
transactionIndex     0
type                 255
blobGasPrice         
blobGasUsed          
to                   0x6BFAf71e3170f3Ae9129810262C2d189128c795f
```

**Need to replace**:
- `MOCK_TOKEN_ADDRESS`: Mock Token address
- `TOKEN_HOME_ADDRESS`: TokenHome address deployed in Step 4

### Step 8: Execute Cross-Chain Token Transfer
Transfer tokens from the source chain to the destination chain.

Estimate fee first: (2147483708 is Ethereum Sepolia chainId)
```bash
cast call 0xc75DFEBF42e2ca4f9F9b90F980B7a484946f94b5 "estimateFee(uint256,uint256)" 2147483708 400000 --rpc-url https://gwan-ssl.wandevs.org:46891 | cast fw

113.971377683383200000
```

Send cross chain transaction with fee.

```bash
cast send TOKEN_HOME_ADDRESS "crossTo(address,uint256)" REMOTE_WALLET_ADDRESS 10ether --rpc-url https://gwan-ssl.wandevs.org:46891 --private-key YOUR_PRIVATE_KEY --legacy --gas-price 4000000000 --value 114ether
```

Output example:
```bash
blockHash            0xe65f54359f21a5e7acaf1c44a8f4feaa024cd6246a02f05f2d9f69bb0e1d6a97
blockNumber          38853721
contractAddress      
cumulativeGasUsed    169936
effectiveGasPrice    4000000000
from                 0x2fb4D46372Ea1748ec3c29Bd2C7B536019DF5200
gasUsed              169936
logs                 [{"address":"0x6bfaf71e3170f3ae9129810262c2d189128c795f","topics":["0xddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef","0x0000000000000000000000002fb4d46372ea1748ec3c29bd2c7b536019df5200","0x000000000000000000000000c75dfebf42e2ca4f9f9b90f980b7a484946f94b5"],"data":"0x0000000000000000000000000000000000000000000000008ac7230489e80000","blockHash":"0xe65f54359f21a5e7acaf1c44a8f4feaa024cd6246a02f05f2d9f69bb0e1d6a97","blockNumber":"0x250dc59","transactionHash":"0x4f7280c5bdf4420a3d3707182a11cd8aa1a96ea154bc5754743564d508f48371","transactionIndex":"0x0","logIndex":"0x0","removed":false},{"address":"0xddddd58428706fedd013b3a761c6e40723a7911d","topics":["0xe2f8f20ddbedfce5eb59a8b930077e7f4906a01300b9318db5f90d1c96c7b6d4","0xee7b01b0828e6b4bfb384cae539e2d9602dd7d6030df7089690dec6a16475afc","0x000000000000000000000000c75dfebf42e2ca4f9f9b90f980b7a484946f94b5","0x000000000000000000000000000000000000000000000000000000008000003c"],"data":"0x000000000000000000000000d6ff848b81db0d8cbb35fed91346554133cf8a73000000000000000000000000000000000000000000000000000000000000004000000000000000000000000000000000000000000000000000000000000000400000000000000000000000002fb4d46372ea1748ec3c29bd2c7b536019df52000000000000000000000000000000000000000000000000008ac7230489e80000","blockHash":"0xe65f54359f21a5e7acaf1c44a8f4feaa024cd6246a02f05f2d9f69bb0e1d6a97","blockNumber":"0x250dc59","transactionHash":"0x4f7280c5bdf4420a3d3707182a11cd8aa1a96ea154bc5754743564d508f48371","transactionIndex":"0x0","logIndex":"0x1","removed":false},{"address":"0xc75dfebf42e2ca4f9f9b90f980b7a484946f94b5","topics":["0x24e9fdf2dc91c9257195c88ddb8a3af9e353f9b6d9e328d553b1f10de71ff59d","0x0000000000000000000000002fb4d46372ea1748ec3c29bd2c7b536019df5200"],"data":"0x0000000000000000000000000000000000000000000000008ac7230489e80000","blockHash":"0xe65f54359f21a5e7acaf1c44a8f4feaa024cd6246a02f05f2d9f69bb0e1d6a97","blockNumber":"0x250dc59","transactionHash":"0x4f7280c5bdf4420a3d3707182a11cd8aa1a96ea154bc5754743564d508f48371","transactionIndex":"0x0","logIndex":"0x2","removed":false}]
logsBloom            0x00000010400240000000000000000000000240000000000000008000000000000000000000000010010000000000000000000000000000000000001000000000200000000000000000000008000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000010000000000000001000000000100000400000000000010000000000000000000000000000000000020004000000000020000002000000000000000000000000100000000000000002001000000000c00000000000000000000000000000002000000400000002000000000000000000000002000000000000000000000000000000000000
root                 
status               1 (success)
transactionHash      0x4f7280c5bdf4420a3d3707182a11cd8aa1a96ea154bc5754743564d508f48371
transactionIndex     0
type                 255
blobGasPrice         
blobGasUsed          
to                   0xc75DFEBF42e2ca4f9F9b90F980B7a484946f94b5
```

**Need to replace**:
- `TOKEN_HOME_ADDRESS`: TokenHome contract address
- `REMOTE_WALLET_ADDRESS`: Remote wallet address
- `--value 114ether`: This is the message fee value, it is different for each remote chain, the extra amount will be returned to you.

### Step 9: Check Cross-Chain Transaction Status
Monitor the processing status of the cross-chain transaction.

```bash
curl -XGET https://testnet.wanscan.org/api/cc/msg/tx?sendTxHash=TRANSACTION_HASH | jq
```

**Need to replace**: `TRANSACTION_HASH` with the actual transaction hash from Step 8 (cross-chain token transfer transaction)

Output example:
```bash
curl -XGET https://testnet.wanscan.org/api/cc/msg/tx\?sendTxHash\=0x4f7280c5bdf4420a3d3707182a11cd8aa1a96ea154bc5754743564d508f48371 | jq
  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
100   819  100   819    0     0    480      0  0:00:01  0:00:01 --:--:--   480
[
  {
    "timestamp": 1758614770,
    "msgs": [
      {
        "to": "0xd6ff848b81db0d8cbb35fed91346554133cf8a73",
        "data": "0x0000000000000000000000002fb4d46372ea1748ec3c29bd2c7b536019df52000000000000000000000000000000000000000000000000008ac7230489e80000"
      }
    ],
    "receiveTimestamp": 1758614869,
    "fee": {
      "value": "113.9713776833832",
      "unit": "WAN",
      "price": "0.098336"
    },
    "cost": {
      "value": "0.00000019716271894",
      "unit": "ETH",
      "price": "4202.88"
    },
    "msgId": "0xee7b01b0828e6b4bfb384cae539e2d9602dd7d6030df7089690dec6a16475afc",
    "fromChain": "WAN",
    "toChain": "ETH",
    "from": "0x2fb4d46372ea1748ec3c29bd2c7b536019df5200",
    "sendTxHash": "0x4f7280c5bdf4420a3d3707182a11cd8aa1a96ea154bc5754743564d508f48371",
    "status": "Success",
    "receiveTxHash": "0x85e6a8a0aa8f429b8e0bfb7062f215dff408cbe3360a8e3b628a87f67f2672dc",
    "smg": "0x000000000000000000000000000000000000000000746573746e65745f303830"
  }
]
```

Wait until the status is Success before proceeding to the next step.

### Step 10: Check Destination Chain Token Balance
Confirm tokens have successfully arrived on the destination chain.

```bash
cast call ERC20_TOKEN_REMOTE_ADDRESS "balanceOf(address)" YOUR_WALLET_ADDRESS --rpc-url https://ethereum-sepolia-rpc.publicnode.com | cast fw
```

Output example:
```bash
cast call 0xd6fF848B81DB0D8cBB35FEd91346554133cF8A73 "balanceOf(address)" 0x2fb4D46372Ea1748ec3c29Bd2C7B536019DF5200 --rpc-url https://ethereum-sepolia-rpc.publicnode.com | cast fw

10.000000000000000000
```

### Step 11: Cross Back Tokens on Destination Chain
Cross back tokens on the destination chain to prepare for cross-chain return.

Estimate fee first: (2147483708 is Wanchain Testnet chainId)
```bash
cast call 0xd6fF848B81DB0D8cBB35FEd91346554133cF8A73 "estimateFee(uint256,uint256)" 2147483708 400000 --rpc-url https://ethereum-sepolia-rpc.publicnode.com | cast fw

0.000800000000000000
```

Send cross chain transaction with fee.

```bash
cast send ERC20_TOKEN_REMOTE_ADDRESS "crossBack(address,uint256)" YOUR_WALLET_ADDRESS 10ether --rpc-url https://ethereum-sepolia-rpc.publicnode.com --private-key YOUR_PRIVATE_KEY --value 0.0008ether
```

Output example:
```bash

blockHash            0x4fafa7626a732ac22d2a6248fdb3e3b0f3e1055fcb1b9d04286d145e3392718c
blockNumber          9261500
contractAddress      
cumulativeGasUsed    4280924
effectiveGasPrice    1022271
from                 0x2fb4D46372Ea1748ec3c29Bd2C7B536019DF5200
gasUsed              102500
logs                 [{"address":"0xd6ff848b81db0d8cbb35fed91346554133cf8a73","topics":["0xddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef","0x0000000000000000000000002fb4d46372ea1748ec3c29bd2c7b536019df5200","0x0000000000000000000000000000000000000000000000000000000000000000"],"data":"0x0000000000000000000000000000000000000000000000008ac7230489e80000","blockHash":"0x4fafa7626a732ac22d2a6248fdb3e3b0f3e1055fcb1b9d04286d145e3392718c","blockNumber":"0x8d51bc","blockTimestamp":"0x68d25890","transactionHash":"0xff701b99ea1fb97f39af3a692024b9b6c16a912a88385f9588a7f549d5ebdde4","transactionIndex":"0x34","logIndex":"0x4a","removed":false},{"address":"0xddddd58428706fedd013b3a761c6e40723a7911d","topics":["0xe2f8f20ddbedfce5eb59a8b930077e7f4906a01300b9318db5f90d1c96c7b6d4","0xac26263215246443ebfa500b2c143e0838a6837c506085847cbd2115271a97c2","0x000000000000000000000000d6ff848b81db0d8cbb35fed91346554133cf8a73","0x000000000000000000000000000000000000000000000000000000008057414e"],"data":"0x000000000000000000000000c75dfebf42e2ca4f9f9b90f980b7a484946f94b5000000000000000000000000000000000000000000000000000000000000004000000000000000000000000000000000000000000000000000000000000000400000000000000000000000002fb4d46372ea1748ec3c29bd2c7b536019df52000000000000000000000000000000000000000000000000008ac7230489e80000","blockHash":"0x4fafa7626a732ac22d2a6248fdb3e3b0f3e1055fcb1b9d04286d145e3392718c","blockNumber":"0x8d51bc","blockTimestamp":"0x68d25890","transactionHash":"0xff701b99ea1fb97f39af3a692024b9b6c16a912a88385f9588a7f549d5ebdde4","transactionIndex":"0x34","logIndex":"0x4b","removed":false},{"address":"0xd6ff848b81db0d8cbb35fed91346554133cf8a73","topics":["0x2426b1e87123e458068dd985e53a28f706052ecf8f4a2efdc870f322111075fe","0x0000000000000000000000002fb4d46372ea1748ec3c29bd2c7b536019df5200"],"data":"0x0000000000000000000000000000000000000000000000008ac7230489e80000","blockHash":"0x4fafa7626a732ac22d2a6248fdb3e3b0f3e1055fcb1b9d04286d145e3392718c","blockNumber":"0x8d51bc","blockTimestamp":"0x68d25890","transactionHash":"0xff701b99ea1fb97f39af3a692024b9b6c16a912a88385f9588a7f549d5ebdde4","transactionIndex":"0x34","logIndex":"0x4c","removed":false}]
logsBloom            0x10008010400000000000000000000000000200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000200000000000000000000008000000000000000000000000000000000000080000000000020000000018000000000800000000000000000000000010000000000000000000000000000000000000000000000040040200200000000000001080000000020004000200000000000000000000000000000000000008000000000000000002000000000000c00002000000000000000000000000000000000420000000000000000000000000000000000000000000000000000000000000000400
root                 
status               1 (success)
transactionHash      0xff701b99ea1fb97f39af3a692024b9b6c16a912a88385f9588a7f549d5ebdde4
transactionIndex     52
type                 2
blobGasPrice         
blobGasUsed          
to                   0xd6fF848B81DB0D8cBB35FEd91346554133cF8A73
```

### Step 12: Check Burn Cross-Chain Status
Monitor the cross-chain return status after token burning.

```bash
curl -XGET https://testnet.wanscan.org/api/cc/msg/tx?sendTxHash=BURN_TRANSACTION_HASH | jq
```

**Need to replace**: `BURN_TRANSACTION_HASH` with the actual transaction hash from Step 11 (token burn transaction)

Output example:
```bash
curl -XGET https://testnet.wanscan.org/api/cc/msg/tx\?sendTxHash\=0xff701b99ea1fb97f39af3a692024b9b6c16a912a88385f9588a7f549d5ebdde4 | jq
  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
100   808  100   808    0     0    409      0  0:00:01  0:00:01 --:--:--   409
[
  {
    "timestamp": 1758615696,
    "msgs": [
      {
        "to": "0xc75dfebf42e2ca4f9f9b90f980b7a484946f94b5",
        "data": "0x0000000000000000000000002fb4d46372ea1748ec3c29bd2c7b536019df52000000000000000000000000000000000000000000000000008ac7230489e80000"
      }
    ],
    "receiveTimestamp": 1758615830,
    "fee": {
      "value": "0.000000051796",
      "unit": "ETH",
      "price": "4212.14"
    },
    "cost": {
      "value": "0.000327542",
      "unit": "WAN",
      "price": "0.098521"
    },
    "msgId": "0xac26263215246443ebfa500b2c143e0838a6837c506085847cbd2115271a97c2",
    "fromChain": "ETH",
    "toChain": "WAN",
    "from": "0x2fb4d46372ea1748ec3c29bd2c7b536019df5200",
    "sendTxHash": "0xff701b99ea1fb97f39af3a692024b9b6c16a912a88385f9588a7f549d5ebdde4",
    "status": "Success",
    "receiveTxHash": "0x2727e0a05301bdd5a988748600e644ed9721f1d0524ff306efe32dc9b5859153",
    "smg": "0x000000000000000000000000000000000000000000746573746e65745f303830"
  }
]
```

Wait until the status is Success before proceeding to the next step.

### Step 13: Check Source Chain Token Balance
Confirm tokens have successfully returned to the source chain.

```bash
cast call MOCK_TOKEN_ADDRESS "balanceOf(address)" YOUR_WALLET_ADDRESS --rpc-url https://gwan-ssl.wandevs.org:46891 | cast fw
```

Output example:
```bash
cast call 0x6BFAf71e3170f3Ae9129810262C2d189128c795f "balanceOf(address)" 0x2fb4D46372Ea1748ec3c29Bd2C7B536019DF5200 --rpc-url https://gwan-ssl.wandevs.org:46891 | cast fw

100.000000000000000000
```

### Step 14: Check Remote Chain Final Balance
Verify tokens have been correctly burned on the destination chain.

```bash
cast call REMOTE_TOKEN_ADDRESS "balanceOf(address)" YOUR_WALLET_ADDRESS --rpc-url https://ethereum-sepolia-rpc.publicnode.com | cast fw
```

Output example:
```bash
cast call 0xd6fF848B81DB0D8cBB35FEd91346554133cF8A73 "balanceOf(address)" 0x2fb4D46372Ea1748ec3c29Bd2C7B536019DF5200 --rpc-url https://ethereum-sepolia-rpc.publicnode.com | cast fw

0.000000000000000000
```

## Important Notes

1. **Variable Updates**: After each step, update the output results to corresponding variables in the next step
2. **Gas Price**: Must use gas price (4000000000) or higher on Wanchain testnet
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
