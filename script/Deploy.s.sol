// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script, console} from "forge-std/Script.sol";
import {DocumentRegistry} from "../src/DocumentSigner.sol";

contract DeployScript is Script {
    function setUp() public {}

    function run() public {
        vm.startBroadcast();

        DocumentRegistry registry = new DocumentRegistry();

        console.log("DocumentRegistry deployed at:", address(registry));

        vm.stopBroadcast();
    }
}
