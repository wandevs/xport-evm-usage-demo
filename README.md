# XPort EVM Cross-Chain Token Transfer Demo

A minimal, end-to-end demo of moving an ERC-20 token between two EVM chains using the [XPort](https://docs.wanchain.org/products/xport) cross-chain messaging protocol on top of the Wanchain Message Bridge (WMB).

The demo deploys three contracts and walks one token round-trip:

- **MockERC20** — an ordinary ERC-20 on the source chain, used as the asset.
- **Erc20TokenHome** — locks the source asset and emits an XPort message when crossing out.
- **Erc20TokenRemote** — the wrapped representation on the destination chain. Mints on inbound messages, burns + emits an XPort message on `crossBack`.

```
[Source chain]                                  [Destination chain]
 MockERC20 ──approve──▶ Erc20TokenHome ──WMB──▶ Erc20TokenRemote ──┐
        ▲                                                          │
        └────────────────── WMB ◀──crossBack──────────────────────┘
```

You can run the whole round-trip with one script (`scripts/run-full-flow.sh`) or follow the manual 14-step walkthrough below.

---

## 1. Prerequisites

Install Foundry:

```bash
curl -L https://foundry.paradigm.xyz | bash
foundryup
forge --version && cast --version
```

Clone and build:

```bash
git clone https://github.com/wandevs/xport-evm-usage-demo.git
cd xport-evm-usage-demo
forge install
forge build
```

You also need `jq` and `curl` for the status-polling commands.

---

## 2. Quickstart — one-command full flow

`scripts/run-full-flow.sh` runs all 14 steps, polling the cross-chain status API between hops. By default it targets **testnet**.

**Testnet (Wanchain → Sepolia):**

```bash
scripts/run-full-flow.sh \
  --source-rpc https://gwan-ssl.wandevs.org:46891 \
  --dest-rpc https://ethereum-sepolia-rpc.publicnode.com \
  --wallet YOUR_WALLET_ADDRESS \
  --private-key YOUR_PRIVATE_KEY
```

**Mainnet (Plasma → Wanchain):** you must override the WMB gateway and the status API for mainnet:

```bash
scripts/run-full-flow.sh \
  --source-rpc https://rpc.plasma.to \
  --dest-rpc https://gwan-ssl.wandevs.org:56891 \
  --wallet YOUR_WALLET_ADDRESS \
  --private-key YOUR_PRIVATE_KEY \
  --wmb-gateway 0x7280E3b8c686c68207aCb1A4D656b2FC8079c033 \
  --status-api https://wanscan.org/api/cc/msg/tx
```

The script:

1. Builds contracts.
2. Deploys MockERC20 on the source chain and mints test tokens.
3. Deploys TokenHome on source and TokenRemote on destination.
4. Waits for the initial cross-chain registration message to reach `Success`.
5. Approves, calls `crossTo`, and waits for the inbound message on destination.
6. Calls `crossBack` from destination, waits for the inbound message on source.
7. Prints addresses, transaction hashes, fees, and final balances.

Run `scripts/run-full-flow.sh --help` for all flags (custom gateway, XPort chain IDs, gas overrides, polling timeout, token name/symbol, `--skip-cross-back`).

---

## 3. Network configuration

The main difference across chains is the EVM version.

| Setting             | Wanchain testnet                         | Wanchain mainnet                         | Avalanche                | Other EVM chains    |
|---------------------|------------------------------------------|------------------------------------------|--------------------------|---------------------|
| `evm_version`       | `london`                                 | `london`                                 | `shanghai`               | default             |
| WMB gateway         | `0xDDddd58428706FEdD013b3A761c6E40723a7911d` | `0x7280E3b8c686c68207aCb1A4D656b2FC8079c033` | same per environment | same per environment |
| Status API          | `https://testnet.wanscan.org/api/cc/msg/tx` | `https://wanscan.org/api/cc/msg/tx`      | same per environment     | same per environment |

Notes:

- `evm_version` is set in `foundry.toml`. Pick the lowest version supported across both endpoints — `london` is the safest baseline.
- The XPort BIP44 chain IDs for each chain live at <https://docs.wanchain.org/products/xport/xport-developer-handbook#id-3.-supported-blockchains>. The full-flow script reads them automatically via `chainId()` on the gateway; for manual deployment you pass them via `SOURCE_XPORT_CHAIN_ID`.

---

## 4. Manual walkthrough (14 steps)

This mirrors what `run-full-flow.sh` does, but using the deploy scripts and `cast` directly. Every step below assumes Wanchain testnet → Sepolia testnet; adapt the RPC URLs per the table above.

Throughout, replace these placeholders with values you collect as you go:

- `YOUR_WALLET_ADDRESS`, `YOUR_PRIVATE_KEY`
- `MOCK_TOKEN_ADDRESS` (output of step 1)
- `TOKEN_HOME_ADDRESS` (output of step 4)
- `TOKEN_REMOTE_ADDRESS` (output of step 5)
- `SOURCE_XPORT_CHAIN_ID` — XPort BIP44 id of the source chain (e.g. `2153201998` for Wanchain testnet)
- `DEST_XPORT_CHAIN_ID` — XPort BIP44 id of the destination chain (e.g. `2147483708` for Sepolia)

### Step 1 — Deploy MockERC20 on the source chain

```bash
forge script script/DeployMockToken.s.sol \
  --rpc-url https://gwan-ssl.wandevs.org:46891 \
  --private-key YOUR_PRIVATE_KEY \
  --broadcast
```

Look for `MockERC20 deployed to: 0x...` in the logs; that's `MOCK_TOKEN_ADDRESS`.

### Step 2 — Mint test tokens

```bash
cast send MOCK_TOKEN_ADDRESS "mint(address,uint256)" YOUR_WALLET_ADDRESS 100ether \
  --rpc-url https://gwan-ssl.wandevs.org:46891 \
  --private-key YOUR_PRIVATE_KEY
```

Expect `status 1 (success)`.

### Step 3 — Check source balance

```bash
cast call MOCK_TOKEN_ADDRESS "balanceOf(address)" YOUR_WALLET_ADDRESS \
  --rpc-url https://gwan-ssl.wandevs.org:46891 | cast fw
# → 100.000000000000000000
```

### Step 4 — Deploy TokenHome on the source chain

The deploy script reads `MOCK_TOKEN_ADDRESS` and (optionally) `WMB_GATEWAY` from the environment:

```bash
MOCK_TOKEN_ADDRESS=0x... \
forge script script/DeployTokenHome.s.sol \
  --rpc-url https://gwan-ssl.wandevs.org:46891 \
  --private-key YOUR_PRIVATE_KEY \
  --broadcast
```

Record `Erc20TokenHome deployed to: 0x...` as `TOKEN_HOME_ADDRESS`.

### Step 5 — Deploy TokenRemote on the destination chain

TokenRemote needs the home address, the source chain's XPort id, and an initial WMB fee paid at construction. Estimate the fee from the destination chain's gateway:

```bash
cast call 0xDDddd58428706FEdD013b3A761c6E40723a7911d \
  "estimateFee(uint256,uint256)(uint256)" SOURCE_XPORT_CHAIN_ID 400000 \
  --rpc-url https://ethereum-sepolia-rpc.publicnode.com
```

Then deploy (use the returned wei value as `REMOTE_INIT_FEE`):

```bash
TOKEN_HOME_ADDRESS=0x... \
SOURCE_XPORT_CHAIN_ID=2153201998 \
REMOTE_INIT_FEE=10000000000000000 \
REMOTE_TOKEN_NAME="Wrapped Test Token" \
REMOTE_TOKEN_SYMBOL="WTT" \
forge script script/DeployTokenRemote.s.sol \
  --rpc-url https://ethereum-sepolia-rpc.publicnode.com \
  --private-key YOUR_PRIVATE_KEY --broadcast
```

Record `Erc20TokenRemote deployed to: 0x...` as `TOKEN_REMOTE_ADDRESS`, and keep the deploy transaction hash — TokenRemote sends a registration message back to TokenHome at construction.

### Step 6 — Wait for the initial cross-chain message

The TokenRemote constructor emits a WMB message that registers it with TokenHome. Poll the status API using the destination deploy tx hash from step 5:

```bash
curl -sG https://testnet.wanscan.org/api/cc/msg/tx \
  --data-urlencode "sendTxHash=DEPLOY_REMOTE_TX_HASH" | jq
```

A `status` of `Success` means the registration message has been relayed. Do not proceed before this.

### Step 7 — Approve TokenHome to spend source tokens

```bash
cast send MOCK_TOKEN_ADDRESS "approve(address,uint256)" TOKEN_HOME_ADDRESS 100ether \
  --rpc-url https://gwan-ssl.wandevs.org:46891 \
  --private-key YOUR_PRIVATE_KEY
```

### Step 8 — `crossTo`: send tokens to the destination chain

Estimate the message fee from TokenHome, then send `crossTo` with `--value` equal to (or slightly above) the estimate — excess is refunded.

```bash
# Estimate fee (DEST_XPORT_CHAIN_ID is the destination's XPort id)
cast call TOKEN_HOME_ADDRESS "estimateFee(uint256,uint256)(uint256)" DEST_XPORT_CHAIN_ID 400000 \
  --rpc-url https://gwan-ssl.wandevs.org:46891 | cast fw
# e.g. 113.971377683383200000

# Send with that value (rounded up)
cast send TOKEN_HOME_ADDRESS "crossTo(address,uint256)" YOUR_WALLET_ADDRESS 10ether \
  --value 114ether \
  --rpc-url https://gwan-ssl.wandevs.org:46891 \
  --private-key YOUR_PRIVATE_KEY
```

### Step 9 — Wait for the `crossTo` message to arrive

```bash
curl -sG https://testnet.wanscan.org/api/cc/msg/tx \
  --data-urlencode "sendTxHash=CROSSTO_TX_HASH" | jq
```

Wait for `status: "Success"`.

### Step 10 — Check destination balance

```bash
cast call TOKEN_REMOTE_ADDRESS "balanceOf(address)" YOUR_WALLET_ADDRESS \
  --rpc-url https://ethereum-sepolia-rpc.publicnode.com | cast fw
# → 10.000000000000000000
```

### Step 11 — `crossBack`: send the wrapped tokens home

```bash
# Estimate fee on the destination chain
cast call TOKEN_REMOTE_ADDRESS "estimateFee(uint256,uint256)(uint256)" SOURCE_XPORT_CHAIN_ID 400000 \
  --rpc-url https://ethereum-sepolia-rpc.publicnode.com | cast fw
# e.g. 0.000800000000000000

# Burn + cross back
cast send TOKEN_REMOTE_ADDRESS "crossBack(address,uint256)" YOUR_WALLET_ADDRESS 10ether \
  --value 0.0008ether \
  --rpc-url https://ethereum-sepolia-rpc.publicnode.com \
  --private-key YOUR_PRIVATE_KEY
```

### Step 12 — Wait for the `crossBack` message

```bash
curl -sG https://testnet.wanscan.org/api/cc/msg/tx \
  --data-urlencode "sendTxHash=CROSSBACK_TX_HASH" | jq
```

Wait for `status: "Success"`.

### Step 13 — Check final source balance

```bash
cast call MOCK_TOKEN_ADDRESS "balanceOf(address)" YOUR_WALLET_ADDRESS \
  --rpc-url https://gwan-ssl.wandevs.org:46891 | cast fw
# → 100.000000000000000000  (fully restored)
```

### Step 14 — Check final destination balance

```bash
cast call TOKEN_REMOTE_ADDRESS "balanceOf(address)" YOUR_WALLET_ADDRESS \
  --rpc-url https://ethereum-sepolia-rpc.publicnode.com | cast fw
# → 0.000000000000000000  (burned on crossBack)
```

---

## 5. Reference

**Cross-chain status API.** Each WMB message can be polled by source-tx hash:

```bash
curl -sG https://testnet.wanscan.org/api/cc/msg/tx \
  --data-urlencode "sendTxHash=0x..." | jq
```

A successful response looks like:

```json
[
  {
    "fromChain": "WAN",
    "toChain": "ETH",
    "sendTxHash": "0x...",
    "receiveTxHash": "0x...",
    "status": "Success",
    "msgId": "0x..."
  }
]
```

While the message is in flight the response is `[]`; treat that as pending and keep polling.

**Common addresses and chain IDs.**

- WMB gateway, testnet: `0xDDddd58428706FEdD013b3A761c6E40723a7911d`
- WMB gateway, mainnet: `0x7280E3b8c686c68207aCb1A4D656b2FC8079c033`
- XPort BIP44 chain IDs: <https://docs.wanchain.org/products/xport/xport-developer-handbook#id-3.-supported-blockchains>
- WMB contracts repo: <https://github.com/wanchain/message-bridge-contracts>

---

## 6. Troubleshooting

- **Polling returns `[]` for a long time on mainnet.** You are probably hitting the testnet API. Pass `--status-api https://wanscan.org/api/cc/msg/tx` (or query it manually). The script's default is testnet.
- **Cross-chain message never reaches `Success`.** Check that (a) TokenHome's wrapper registration completed (step 6) before any `crossTo`, (b) the `--value` you sent covers the latest `estimateFee` result, and (c) the source/destination XPort chain IDs are correct.
- **Contract deploy fails with EVM-version errors.** Adjust `evm_version` in `foundry.toml` — `london` for Wanchain, `shanghai` for Avalanche.
- **`crossTo` reverts on approve.** Some legacy ERC-20s (e.g. USDT) require `approve(spender, 0)` before changing a non-zero allowance. The MockERC20 in this demo doesn't, but real assets often do.

For deeper inspection, look up transactions on the relevant explorer and inspect the WMB events emitted by the gateway (`0xe2f8f20d...` topic = outbound message).
