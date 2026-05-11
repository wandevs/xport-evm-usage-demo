// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script} from "forge-std/Script.sol";
import {Erc20TokenHome} from "../src/Erc20TokenHome.sol";
import {console} from "forge-std/console.sol";

contract DeployTokenHome is Script {
    function run() public {

        address wmbGateway = vm.envOr("WMB_GATEWAY", address(0xDDddd58428706FEdD013b3A761c6E40723a7911d)); // Testnet
        address token = vm.envAddress("MOCK_TOKEN_ADDRESS");

        vm.startBroadcast();

        Erc20TokenHome tokenHome = new Erc20TokenHome(wmbGateway, token);

        vm.stopBroadcast();

        console.log("Erc20TokenHome deployed to:", address(tokenHome));
    }
}
