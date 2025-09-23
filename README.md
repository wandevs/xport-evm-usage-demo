
1. Deploy mock token on source chain
forge script script/DeployMockToken.s.sol --rpc-url https://gwan-ssl.wandevs.org:46891 --private-key YOUR_PRIVATE_KEY --broadcast --legacy --with-gas-price 4000000000

2. Faucet mock token on source chain
cast send MOCK_TOKEN_ADDRESS "mint(address,uint256)" YOUR_WALLET_ADDRESS 100ether --rpc-url https://gwan-ssl.wandevs.org:46891 --private-key YOUR_PRIVATE_KEY --legacy --gas-price 4000000000

3. Check mock token balance of your wallet
cast call MOCK_TOKEN_ADDRESS "balanceOf(address)" YOUR_WALLET_ADDRESS --rpc-url https://gwan-ssl.wandevs.org:46891

4. Deploy token home contract on source chain (Such as wanchain testnet)
forge script script/DeployTokenHome.s.sol --rpc-url https://gwan-ssl.wandevs.org:46891 --private-key YOUR_PRIVATE_KEY --broadcast --legacy --with-gas-price 4000000000

5. Deploy token remote contract on remote chain (Such as ethereum sepolia)
forge script script/DeployTokenRemote.s.sol --rpc-url https://ethereum-sepolia-rpc.publicnode.com --private-key YOUR_PRIVATE_KEY --broadcast

6. Query initial message cross status
curl -XGET https://testnet.wanscan.org/api/cc/msg/tx\?sendTxHash\=0x76bb15b56143f7e4e760c5adf02b144b17a12727e296ebd4f212d27e72851c7a | jq

7. Approve token on the source chain
cast send MOCK_TOKEN_ADDRESS "approve(address,uint256)" TOKEN_HOME_ADDRESS 100ether --rpc-url https://gwan-ssl.wandevs.org:46891 --private-key YOUR_PRIVATE_KEY --legacy --gas-price 4000000000

8. Cross chain token from source chain to remote chain
cast send TOKEN_HOME_ADDRESS "crossTo(address,uint256)" REMOTE_TOKEN_ADDRESS 100ether --rpc-url https://gwan-ssl.wandevs.org:46891 --private-key YOUR_PRIVATE_KEY --legacy --gas-price 4000000000 --value 0.01 ether

9. Query cross status of the cross chain token
curl -XGET https://testnet.wanscan.org/api/cc/msg/tx\?sendTxHash\=0x76bb15b56143f7e4e760c5adf02b144b17a12727e296ebd4f212d27e72851c7a | jq

10. Check remote token balance of your wallet
cast call REMOTE_TOKEN_ADDRESS "balanceOf(address)" YOUR_WALLET_ADDRESS --rpc-url https://ethereum-sepolia-rpc.publicnode.com

11. Burn remote token on remote chain
cast send REMOTE_TOKEN_ADDRESS "burn(address,uint256)" YOUR_WALLET_ADDRESS 100ether --rpc-url https://ethereum-sepolia-rpc.publicnode.com --private-key YOUR_PRIVATE_KEY --legacy --gas-price 4000000000

12. Query cross status of the cross chain token
curl -XGET https://testnet.wanscan.org/api/cc/msg/tx\?sendTxHash\=0x76bb15b56143f7e4e760c5adf02b144b17a12727e296ebd4f212d27e72851c7a | jq

13. Check mock token balance of your wallet
cast call MOCK_TOKEN_ADDRESS "balanceOf(address)" YOUR_WALLET_ADDRESS --rpc-url https://gwan-ssl.wandevs.org:46891

14. Check remote token balance of your wallet
cast call REMOTE_TOKEN_ADDRESS "balanceOf(address)" YOUR_WALLET_ADDRESS --rpc-url https://ethereum-sepolia-rpc.publicnode.com

