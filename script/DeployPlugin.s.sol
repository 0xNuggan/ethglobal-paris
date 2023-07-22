// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Script.sol";

import {SymbioticBondingCurvePluginSetup} from "../src/SymbioticBondingCurvePluginSetup.sol";
import {SymbioticBondingCurvePlugin} from "../src/SymbioticBondingCurvePlugin.sol";

contract PluginScript is Script {
    function setUp() public {}

    function run() public {
        uint256 deployerPrivateKey = vm.envUint("WALLET_DEPLOYER_PK");
        vm.startBroadcast(deployerPrivateKey);

        
        SymbioticBondingCurvePluginSetup bc_setup = new SymbioticBondingCurvePluginSetup();


        vm.stopBroadcast();


    }
}
