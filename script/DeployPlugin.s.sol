// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import "forge-std/console.sol";

import {SymbioticBondingCurvePluginSetup} from "../src/SymbioticBondingCurvePluginSetup.sol";
import {SymbioticBondingCurvePlugin} from "../src/SymbioticBondingCurvePlugin.sol";
import {MockLSD} from "../src/mockContracts/MockLSD.sol";

contract PluginScript is Script {
    function setUp() public {}

    function run() public {
        address targetDAO = vm.envAddress("TARGET_DAO");
        uint256 deployerPrivateKey = vm.envUint("WALLET_DEPLOYER_PK");
        address deployer = vm.envAddress("WALLET_DEPLOYER");
        vm.startBroadcast(deployerPrivateKey);


        MockLSD rebasingReserve = new MockLSD("LSD", "LSD");       
        console.log("MockLSD deployed to: %s", address(rebasingReserve));


        
        SymbioticBondingCurvePluginSetup bc_setup = new SymbioticBondingCurvePluginSetup();

        console.log("PluginSetup deployed to: %s", address(bc_setup));
        console.log("Plugin implementation deployed to: %s", address(bc_setup.implementation()));


        rebasingReserve.mint(address(bc_setup), 10 ether); //ether used as a shorthand for 1e18
        console.log("Seeded Setup with 10 tokens for initialization");

        address _dao = targetDAO; // the DAO we want to install the plugin to


        address pluginAdmin = address(deployer);
        address reserveToken = address(rebasingReserve);
        address relayForwarder = address(0xb539068872230f20456CF38EC52EF2f91AF4AE49); //Gelato Relay
        uint initialReserve = 10 ether;  // the amunt we seeded the setup with
        uint32 reserveRatio = 300000; // initial reserve ratio
        address treasuryReceiver = _dao; // we specify the main DAO treasury as benficieary of the surplus

        bytes memory initData =
            abi.encode(
                pluginAdmin,  
                reserveToken,  
                relayForwarder, 
                initialReserve,
                reserveRatio,
                treasuryReceiver
            );

        bc_setup.prepareInstallation(_dao, initData);

        console.log("Plugin Installation Prepared. Bonding Curve Initialized.");

        vm.stopBroadcast();


        // At this point, what is missing is for the target DAO to pass a proposal, which will execute applyInstallation() and integrate the plugin into the DAO.

    }
}
