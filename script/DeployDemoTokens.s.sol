// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import "forge-std/console.sol";

import {SymbioticBondingCurvePluginSetup} from "../src/SymbioticBondingCurvePluginSetup.sol";
import {SymbioticBondingCurvePlugin} from "../src/SymbioticBondingCurvePlugin.sol";
import {MockLSD} from "../src/mockContracts/MockLSD.sol";
import {MockToken} from "../src/mockContracts/MockToken.sol";

contract TokenDeployerScript is Script {
    function setUp() public {}

    function run() public {


        uint256 deployerPrivateKey = vm.envUint("WALLET_DEPLOYER_PK");
        address deployer = vm.envAddress("WALLET_DEPLOYER");


        vm.startBroadcast(deployerPrivateKey);

        MockToken underlyingToken = new MockToken("ProtocolToken", "PTK");       
        console.log("Mock Protocol Token deployed to: %s", address(underlyingToken));

        MockLSD rebasingReserve = new MockLSD("LSD", "LSD", address(underlyingToken));       
        console.log("MockLSD deployed to: %s", address(rebasingReserve));

        underlyingToken.mint(address(deployer), 100000 ether);
        console.log("Deployer Wallet Funded with 100000 Tokens.");

        vm.stopBroadcast();
    }
}