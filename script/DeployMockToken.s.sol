// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script} from "forge-std/Script.sol";
import {MockERC20} from "../src/MockErc20.sol";
import {console} from "forge-std/console.sol";

contract DeployMockToken is Script {
    function run() public {
        vm.startBroadcast();

        MockERC20 mockToken = new MockERC20();

        vm.stopBroadcast();

        console.log("MockERC20 deployed to:", address(mockToken));
    }
}
