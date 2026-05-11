#!/usr/bin/env bash
set -euo pipefail

SOURCE_RPC=""
DEST_RPC=""
WALLET=""
PRIVATE_KEY=""

SOURCE_XPORT_CHAIN_ID=""
DEST_XPORT_CHAIN_ID=""
WMB_GATEWAY="0xDDddd58428706FEdD013b3A761c6E40723a7911d"
MINT_AMOUNT="100ether"
TRANSFER_AMOUNT="10ether"
REMOTE_TOKEN_NAME="Wrapped Test Token"
REMOTE_TOKEN_SYMBOL="WTT"
REMOTE_INIT_FEE=""
SOURCE_LEGACY="true"
SOURCE_GAS_PRICE="4000000000"
DEST_LEGACY="false"
DEST_GAS_PRICE=""
GAS_LIMIT="400000"
STATUS_API="https://testnet.wanscan.org/api/cc/msg/tx"
STATUS_TIMEOUT="900"
STATUS_INTERVAL="15"
SKIP_CROSS_BACK="false"

usage() {
  cat <<'USAGE'
Usage:
  scripts/run-full-flow.sh \
    --source-rpc <url> \
    --dest-rpc <url> \
    --wallet <address> \
    --private-key <private-key>

Required:
  --source-rpc              Source chain RPC URL
  --dest-rpc                Destination chain RPC URL
  --wallet                  Wallet address used for minting and receiving
  --private-key             Private key used for deployments and transactions

Optional defaults match the README testnet example:
  --source-xport-chain-id   Source XPort BIP44 chain id. If omitted, read WMB gateway chainId() on source RPC.
  --dest-xport-chain-id     Destination XPort BIP44 chain id. If omitted, read WMB gateway chainId() on destination RPC.
  --wmb-gateway             WMB gateway address, default: 0xDDddd58428706FEdD013b3A761c6E40723a7911d
  --mint-amount             Amount minted on source, default: 100ether
  --transfer-amount         Amount crossed each way, default: 10ether
  --remote-name             Wrapped token name, default: Wrapped Test Token
  --remote-symbol           Wrapped token symbol, default: WTT
  --remote-init-fee         Initial remote deployment fee in wei. If omitted, the script estimates it.
  --source-legacy           true/false, default: true
  --source-gas-price        Source gas price in wei, default: 4000000000
  --dest-legacy             true/false, default: false
  --dest-gas-price          Destination gas price in wei, optional
  --status-api              Cross-chain status API, default: https://testnet.wanscan.org/api/cc/msg/tx
  --status-timeout          Status wait timeout seconds, default: 900
  --status-interval         Poll interval seconds, default: 15
  --skip-cross-back         Skip destination-to-source return flow

Example:
  scripts/run-full-flow.sh \
    --source-rpc https://gwan-ssl.wandevs.org:46891 \
    --dest-rpc https://ethereum-sepolia-rpc.publicnode.com \
    --wallet 0xYourWallet \
    --private-key 0xYourPrivateKey
USAGE
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --source-rpc) SOURCE_RPC="$2"; shift 2 ;;
    --dest-rpc) DEST_RPC="$2"; shift 2 ;;
    --wallet) WALLET="$2"; shift 2 ;;
    --private-key) PRIVATE_KEY="$2"; shift 2 ;;
    --source-xport-chain-id) SOURCE_XPORT_CHAIN_ID="$2"; shift 2 ;;
    --dest-xport-chain-id) DEST_XPORT_CHAIN_ID="$2"; shift 2 ;;
    --wmb-gateway) WMB_GATEWAY="$2"; shift 2 ;;
    --mint-amount) MINT_AMOUNT="$2"; shift 2 ;;
    --transfer-amount) TRANSFER_AMOUNT="$2"; shift 2 ;;
    --remote-name) REMOTE_TOKEN_NAME="$2"; shift 2 ;;
    --remote-symbol) REMOTE_TOKEN_SYMBOL="$2"; shift 2 ;;
    --remote-init-fee) REMOTE_INIT_FEE="$2"; shift 2 ;;
    --source-legacy) SOURCE_LEGACY="$2"; shift 2 ;;
    --source-gas-price) SOURCE_GAS_PRICE="$2"; shift 2 ;;
    --dest-legacy) DEST_LEGACY="$2"; shift 2 ;;
    --dest-gas-price) DEST_GAS_PRICE="$2"; shift 2 ;;
    --status-api) STATUS_API="$2"; shift 2 ;;
    --status-timeout) STATUS_TIMEOUT="$2"; shift 2 ;;
    --status-interval) STATUS_INTERVAL="$2"; shift 2 ;;
    --skip-cross-back) SKIP_CROSS_BACK="true"; shift ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown argument: $1" >&2; usage; exit 1 ;;
  esac
done

require_arg() {
  local name="$1"
  local value="$2"
  if [[ -z "$value" ]]; then
    echo "Missing required argument: $name" >&2
    usage
    exit 1
  fi
}

require_cmd() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "Missing required command: $1" >&2
    exit 1
  fi
}

log() {
  printf '\n[%s] %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$*"
}

run() {
  local masked=()
  local hide_next="false"
  local arg
  for arg in "$@"; do
    if [[ "$hide_next" == "true" ]]; then
      masked+=("***")
      hide_next="false"
    elif [[ "$arg" == "--private-key" ]]; then
      masked+=("$arg")
      hide_next="true"
    else
      masked+=("$arg")
    fi
  done
  log "${masked[*]}"
  "$@"
}

tx_args() {
  local legacy="$1"
  local gas_price="$2"
  if [[ "$legacy" == "true" ]]; then
    printf '%s\n' "--legacy"
  fi
  if [[ -n "$gas_price" ]]; then
    printf '%s\n' "--gas-price"
    printf '%s\n' "$gas_price"
  fi
}

script_args() {
  local legacy="$1"
  local gas_price="$2"
  if [[ "$legacy" == "true" ]]; then
    printf '%s\n' "--legacy"
  fi
  if [[ -n "$gas_price" ]]; then
    printf '%s\n' "--with-gas-price"
    printf '%s\n' "$gas_price"
  fi
}

latest_broadcast_json() {
  local script_name="$1"
  local chain_id="$2"
  printf 'broadcast/%s/%s/run-latest.json' "$script_name" "$chain_id"
}

extract_contract_address() {
  local file="$1"
  jq -er '.transactions[] | select(.contractAddress != null and .contractAddress != "") | .contractAddress' "$file" | tail -n 1
}

extract_tx_hash() {
  local file="$1"
  jq -er '.transactions[] | select(.hash != null and .hash != "") | .hash' "$file" | tail -n 1
}

send_tx() {
  local rpc="$1"
  shift
  local json
  json="$("$@" --rpc-url "$rpc" --private-key "$PRIVATE_KEY" --json)"
  echo "$json" | jq -r '.transactionHash // .hash'
}

format_units() {
  cast format-units "$(normalize_uint "$1")" 18
}

to_dec() {
  local value
  value="$(normalize_uint "$1")"
  if [[ "$value" == 0x* ]]; then
    cast to-dec "$value"
  else
    printf '%s\n' "$value"
  fi
}

normalize_uint() {
  printf '%s\n' "$1" | awk '{print $1}'
}

read_xport_chain_id() {
  local rpc="$1"
  local label="$2"
  local value
  if ! value="$(cast call "$WMB_GATEWAY" "chainId()(uint256)" --rpc-url "$rpc" 2>/dev/null)"; then
    echo "Could not read $label XPort BIP44 chain id from WMB gateway $WMB_GATEWAY. Pass --${label}-xport-chain-id explicitly." >&2
    exit 1
  fi
  to_dec "$value"
}

wait_cc_success() {
  local tx_hash="$1"
  local label="$2"
  local start
  start="$(date +%s)"

  while true; do
    local body status elapsed
    body="$(curl -fsS --get "$STATUS_API" --data-urlencode "sendTxHash=$tx_hash" || true)"
    status="$(echo "$body" | jq -r 'if type == "array" and length > 0 then .[0].status else empty end' 2>/dev/null || true)"

    if [[ "$status" == "Success" ]]; then
      log "$label cross-chain status: Success"
      echo "$body" | jq .
      return 0
    fi

    elapsed=$(($(date +%s) - start))
    if (( elapsed >= STATUS_TIMEOUT )); then
      echo "$body" | jq . 2>/dev/null || echo "$body"
      echo "Timed out waiting for $label cross-chain status after ${STATUS_TIMEOUT}s" >&2
      exit 1
    fi

    if [[ -z "$status" ]]; then
      log "$label cross-chain status: pending/no record yet (${elapsed}s elapsed)"
    else
      log "$label cross-chain status: $status (${elapsed}s elapsed)"
    fi
    sleep "$STATUS_INTERVAL"
  done
}

require_arg "--source-rpc" "$SOURCE_RPC"
require_arg "--dest-rpc" "$DEST_RPC"
require_arg "--wmb-gateway" "$WMB_GATEWAY"
require_arg "--wallet" "$WALLET"
require_arg "--private-key" "$PRIVATE_KEY"

require_cmd forge
require_cmd cast
require_cmd jq
require_cmd curl

cd "$(dirname "$0")/.."

SOURCE_EVM_CHAIN_ID="$(cast chain-id --rpc-url "$SOURCE_RPC")"
DEST_EVM_CHAIN_ID="$(cast chain-id --rpc-url "$DEST_RPC")"
if [[ -z "$SOURCE_XPORT_CHAIN_ID" ]]; then
  SOURCE_XPORT_CHAIN_ID="$(read_xport_chain_id "$SOURCE_RPC" source)"
fi
if [[ -z "$DEST_XPORT_CHAIN_ID" ]]; then
  DEST_XPORT_CHAIN_ID="$(read_xport_chain_id "$DEST_RPC" dest)"
fi

log "Configuration"
cat <<EOF
  Source RPC:              $SOURCE_RPC
  Destination RPC:         $DEST_RPC
  Wallet:                  $WALLET
  Source EVM chain id:     $SOURCE_EVM_CHAIN_ID
  Destination EVM chain id:$DEST_EVM_CHAIN_ID
  Source XPort chain id:   $SOURCE_XPORT_CHAIN_ID
  Destination XPort id:    $DEST_XPORT_CHAIN_ID
  WMB gateway:             $WMB_GATEWAY
  Mint amount:             $MINT_AMOUNT
  Transfer amount:         $TRANSFER_AMOUNT
EOF

log "Building contracts"
run forge build

log "Step 1/14 Deploy MockERC20 on source chain"
SOURCE_SCRIPT_ARGS=()
if [[ "$SOURCE_LEGACY" == "true" ]]; then
  SOURCE_SCRIPT_ARGS+=("--legacy")
fi
if [[ -n "$SOURCE_GAS_PRICE" ]]; then
  SOURCE_SCRIPT_ARGS+=("--with-gas-price" "$SOURCE_GAS_PRICE")
fi
run forge script script/DeployMockToken.s.sol --rpc-url "$SOURCE_RPC" --private-key "$PRIVATE_KEY" --broadcast ${SOURCE_SCRIPT_ARGS[@]+"${SOURCE_SCRIPT_ARGS[@]}"}
MOCK_JSON="$(latest_broadcast_json DeployMockToken.s.sol "$SOURCE_EVM_CHAIN_ID")"
MOCK_TOKEN_ADDRESS="$(extract_contract_address "$MOCK_JSON")"
MOCK_DEPLOY_TX="$(extract_tx_hash "$MOCK_JSON")"
log "MockERC20: $MOCK_TOKEN_ADDRESS"
log "MockERC20 deploy tx: $MOCK_DEPLOY_TX"

log "Step 2/14 Mint source tokens"
SOURCE_TX_ARGS=()
if [[ "$SOURCE_LEGACY" == "true" ]]; then
  SOURCE_TX_ARGS+=("--legacy")
fi
if [[ -n "$SOURCE_GAS_PRICE" ]]; then
  SOURCE_TX_ARGS+=("--gas-price" "$SOURCE_GAS_PRICE")
fi
MINT_TX="$(send_tx "$SOURCE_RPC" cast send "$MOCK_TOKEN_ADDRESS" "mint(address,uint256)" "$WALLET" "$MINT_AMOUNT" ${SOURCE_TX_ARGS[@]+"${SOURCE_TX_ARGS[@]}"})"
log "Mint tx: $MINT_TX"

log "Step 3/14 Check source token balance"
SOURCE_BALANCE_WEI="$(to_dec "$(cast call "$MOCK_TOKEN_ADDRESS" "balanceOf(address)(uint256)" "$WALLET" --rpc-url "$SOURCE_RPC")")"
log "Source token balance: $(format_units "$SOURCE_BALANCE_WEI")"

log "Step 4/14 Deploy TokenHome on source chain"
run env MOCK_TOKEN_ADDRESS="$MOCK_TOKEN_ADDRESS" WMB_GATEWAY="$WMB_GATEWAY" \
  forge script script/DeployTokenHome.s.sol --rpc-url "$SOURCE_RPC" --private-key "$PRIVATE_KEY" --broadcast ${SOURCE_SCRIPT_ARGS[@]+"${SOURCE_SCRIPT_ARGS[@]}"}
HOME_JSON="$(latest_broadcast_json DeployTokenHome.s.sol "$SOURCE_EVM_CHAIN_ID")"
TOKEN_HOME_ADDRESS="$(extract_contract_address "$HOME_JSON")"
HOME_DEPLOY_TX="$(extract_tx_hash "$HOME_JSON")"
log "TokenHome: $TOKEN_HOME_ADDRESS"
log "TokenHome deploy tx: $HOME_DEPLOY_TX"

log "Step 5/14 Deploy TokenRemote on destination chain"
if [[ -z "$REMOTE_INIT_FEE" ]]; then
  REMOTE_INIT_FEE="$(to_dec "$(cast call "$WMB_GATEWAY" "estimateFee(uint256,uint256)(uint256)" "$SOURCE_XPORT_CHAIN_ID" "$GAS_LIMIT" --rpc-url "$DEST_RPC")")"
  log "Estimated remote init fee: $REMOTE_INIT_FEE wei ($(format_units "$REMOTE_INIT_FEE"))"
else
  log "Using provided remote init fee: $REMOTE_INIT_FEE wei ($(format_units "$REMOTE_INIT_FEE"))"
fi
DEST_SCRIPT_ARGS=()
if [[ "$DEST_LEGACY" == "true" ]]; then
  DEST_SCRIPT_ARGS+=("--legacy")
fi
if [[ -n "$DEST_GAS_PRICE" ]]; then
  DEST_SCRIPT_ARGS+=("--with-gas-price" "$DEST_GAS_PRICE")
fi
run env TOKEN_HOME_ADDRESS="$TOKEN_HOME_ADDRESS" SOURCE_XPORT_CHAIN_ID="$SOURCE_XPORT_CHAIN_ID" WMB_GATEWAY="$WMB_GATEWAY" \
  REMOTE_TOKEN_NAME="$REMOTE_TOKEN_NAME" REMOTE_TOKEN_SYMBOL="$REMOTE_TOKEN_SYMBOL" REMOTE_INIT_FEE="$REMOTE_INIT_FEE" \
  forge script script/DeployTokenRemote.s.sol --rpc-url "$DEST_RPC" --private-key "$PRIVATE_KEY" --broadcast ${DEST_SCRIPT_ARGS[@]+"${DEST_SCRIPT_ARGS[@]}"}
REMOTE_JSON="$(latest_broadcast_json DeployTokenRemote.s.sol "$DEST_EVM_CHAIN_ID")"
TOKEN_REMOTE_ADDRESS="$(extract_contract_address "$REMOTE_JSON")"
REMOTE_DEPLOY_TX="$(extract_tx_hash "$REMOTE_JSON")"
log "TokenRemote: $TOKEN_REMOTE_ADDRESS"
log "TokenRemote deploy tx: $REMOTE_DEPLOY_TX"

log "Step 6/14 Wait for initial cross-chain message"
wait_cc_success "$REMOTE_DEPLOY_TX" "Initial"

log "Step 7/14 Approve TokenHome to spend source tokens"
APPROVE_TX="$(send_tx "$SOURCE_RPC" cast send "$MOCK_TOKEN_ADDRESS" "approve(address,uint256)" "$TOKEN_HOME_ADDRESS" "$MINT_AMOUNT" ${SOURCE_TX_ARGS[@]+"${SOURCE_TX_ARGS[@]}"})"
log "Approve tx: $APPROVE_TX"

log "Step 8/14 Cross source tokens to destination"
CROSS_TO_FEE="$(to_dec "$(cast call "$TOKEN_HOME_ADDRESS" "estimateFee(uint256,uint256)(uint256)" "$DEST_XPORT_CHAIN_ID" "$GAS_LIMIT" --rpc-url "$SOURCE_RPC")")"
log "Estimated crossTo fee: $CROSS_TO_FEE wei ($(format_units "$CROSS_TO_FEE"))"
CROSS_TO_TX="$(send_tx "$SOURCE_RPC" cast send "$TOKEN_HOME_ADDRESS" "crossTo(address,uint256)" "$WALLET" "$TRANSFER_AMOUNT" --value "$CROSS_TO_FEE" ${SOURCE_TX_ARGS[@]+"${SOURCE_TX_ARGS[@]}"})"
log "crossTo tx: $CROSS_TO_TX"

log "Step 9/14 Wait for crossTo message"
wait_cc_success "$CROSS_TO_TX" "crossTo"

log "Step 10/14 Check destination token balance"
DEST_BALANCE_WEI="$(to_dec "$(cast call "$TOKEN_REMOTE_ADDRESS" "balanceOf(address)(uint256)" "$WALLET" --rpc-url "$DEST_RPC")")"
log "Destination token balance: $(format_units "$DEST_BALANCE_WEI")"

if [[ "$SKIP_CROSS_BACK" == "true" ]]; then
  log "Skipping steps 11-14 because --skip-cross-back was provided"
  exit 0
fi

log "Step 11/14 Cross destination tokens back to source"
DEST_TX_ARGS=()
if [[ "$DEST_LEGACY" == "true" ]]; then
  DEST_TX_ARGS+=("--legacy")
fi
if [[ -n "$DEST_GAS_PRICE" ]]; then
  DEST_TX_ARGS+=("--gas-price" "$DEST_GAS_PRICE")
fi
CROSS_BACK_FEE="$(to_dec "$(cast call "$TOKEN_REMOTE_ADDRESS" "estimateFee(uint256,uint256)(uint256)" "$SOURCE_XPORT_CHAIN_ID" "$GAS_LIMIT" --rpc-url "$DEST_RPC")")"
log "Estimated crossBack fee: $CROSS_BACK_FEE wei ($(format_units "$CROSS_BACK_FEE"))"
CROSS_BACK_TX="$(send_tx "$DEST_RPC" cast send "$TOKEN_REMOTE_ADDRESS" "crossBack(address,uint256)" "$WALLET" "$TRANSFER_AMOUNT" --value "$CROSS_BACK_FEE" ${DEST_TX_ARGS[@]+"${DEST_TX_ARGS[@]}"})"
log "crossBack tx: $CROSS_BACK_TX"

log "Step 12/14 Wait for crossBack message"
wait_cc_success "$CROSS_BACK_TX" "crossBack"

log "Step 13/14 Check final source token balance"
FINAL_SOURCE_BALANCE_WEI="$(to_dec "$(cast call "$MOCK_TOKEN_ADDRESS" "balanceOf(address)(uint256)" "$WALLET" --rpc-url "$SOURCE_RPC")")"
log "Final source token balance: $(format_units "$FINAL_SOURCE_BALANCE_WEI")"

log "Step 14/14 Check final destination token balance"
FINAL_DEST_BALANCE_WEI="$(to_dec "$(cast call "$TOKEN_REMOTE_ADDRESS" "balanceOf(address)(uint256)" "$WALLET" --rpc-url "$DEST_RPC")")"
log "Final destination token balance: $(format_units "$FINAL_DEST_BALANCE_WEI")"

log "Done"
cat <<EOF
Mock token:    $MOCK_TOKEN_ADDRESS
TokenHome:     $TOKEN_HOME_ADDRESS
TokenRemote:   $TOKEN_REMOTE_ADDRESS
Mint tx:       $MINT_TX
crossTo tx:    $CROSS_TO_TX
crossBack tx:  $CROSS_BACK_TX
EOF
