// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script} from "forge-std/Script.sol";
import {Erc20TokenHome} from "../src/Erc20TokenHome.sol";
import {console} from "forge-std/console.sol";

contract DeployTokenHome is Script {
    function run() public {

        address wmbGateway = 0xDDddd58428706FEdD013b3A761c6E40723a7911d; // Testnet
        // address wmbGateway = 0x7280E3b8c686c68207aCb1A4D656b2FC8079c033; // Mainnet

        address token = 0x40E73F350A2245717B5c7D15845D926e8aE3041E;

        vm.startBroadcast();

        Erc20TokenHome tokenHome = new Erc20TokenHome(wmbGateway, token);

        vm.stopBroadcast();

        console.log("Erc20TokenHome deployed to:", address(tokenHome));
    }
}
