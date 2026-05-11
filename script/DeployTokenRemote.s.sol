// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script} from "forge-std/Script.sol";
import {Erc20TokenRemote} from "../src/Erc20TokenRemote.sol";
import {console} from "forge-std/console.sol";

contract DeployTokenRemote is Script {
    function run() public {

        address wmbGateway = vm.envOr("WMB_GATEWAY", address(0xDDddd58428706FEdD013b3A761c6E40723a7911d)); // Testnet
        address _remoteSc = vm.envAddress("TOKEN_HOME_ADDRESS"); // Token Home address on source chain
        uint256 _remoteChainId = vm.envUint("SOURCE_XPORT_CHAIN_ID"); // source chain id
        string memory _name = vm.envOr("REMOTE_TOKEN_NAME", string("Wrapped Test Token"));
        string memory _symbol = vm.envOr("REMOTE_TOKEN_SYMBOL", string("WTT"));

        uint256 initFee = vm.envOr("REMOTE_INIT_FEE", uint256(0.01 ether)); // message bridge fee for the first initial tx

        vm.startBroadcast();

        Erc20TokenRemote tokenRemote = new Erc20TokenRemote{value: initFee}(wmbGateway, _remoteSc, _remoteChainId, _name, _symbol);

        vm.stopBroadcast();

        console.log("Erc20TokenRemote deployed to:", address(tokenRemote));
    }
}
