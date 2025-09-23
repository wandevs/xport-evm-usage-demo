// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script} from "forge-std/Script.sol";
import {Erc20TokenRemote} from "../src/Erc20TokenRemote.sol";
import {console} from "forge-std/console.sol";

contract DeployTokenRemote is Script {
    function run() public {

        address wmbGateway = 0xDDddd58428706FEdD013b3A761c6E40723a7911d; // Testnet
        // address wmbGateway = 0x7280E3b8c686c68207aCb1A4D656b2FC8079c033; // Mainnet

        address _remoteSc = 0xc75DFEBF42e2ca4f9F9b90F980B7a484946f94b5; // Token Home address on source chain
        uint256 _remoteChainId = 2153201998; // source chain id
        string memory _name = "Wrapped Test Token"; 
        string memory _symbol = "WTT";

        uint256 initFee = 0.01 ether; // the message bridge fee for the first initial tx.

        vm.startBroadcast();

        Erc20TokenRemote tokenRemote = new Erc20TokenRemote{value: initFee}(wmbGateway, _remoteSc, _remoteChainId, _name, _symbol);

        vm.stopBroadcast();

        console.log("Erc20TokenRemote deployed to:", address(tokenRemote));
    }
}
