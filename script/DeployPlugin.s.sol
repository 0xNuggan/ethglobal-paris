// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import "forge-std/Test.sol";
import "forge-std/console.sol";

import {SymbioticBondingCurvePluginSetup} from "../src/SymbioticBondingCurvePluginSetup.sol";
import {SymbioticBondingCurvePlugin} from "../src/SymbioticBondingCurvePlugin.sol";
import {MockLSD} from "../src/mockContracts/MockLSD.sol";
import {MockToken} from "../src/mockContracts/MockToken.sol";

import {PluginRepoFactory, PluginRepo} from "@aragon/osx/framework/plugin/repo/PluginRepoFactory.sol";

contract PluginScript is Script {

    MockToken underlyingToken = MockToken(vm.envAddress("UNDERLYING_TOKEN")); 
    MockLSD rebasingReserve = MockLSD(vm.envAddress("RESERVE_TOKEN"));

    PluginRepoFactory pluginRepoFactory = PluginRepoFactory(vm.envAddress("PLUGIN_REPO_FACTORY"));

    function setUp() public {
        //Mock Setup step for local runs

        /*
        uint256 deployerPrivateKey = vm.envUint("WALLET_DEPLOYER_PK");
        address deployer = vm.envAddress("WALLET_DEPLOYER");


        vm.startBroadcast(deployerPrivateKey);

        underlyingToken = new MockToken("ProtocolToken", "PTK");       
        console.log("Mock Protocol Token deployed to: %s", address(underlyingToken));

        rebasingReserve = new MockLSD("LSD", "LSD", address(underlyingToken));       
        console.log("MockLSD deployed to: %s", address(rebasingReserve));

        underlyingToken.mint(address(deployer), 100000 ether);
        console.log("Deployer Wallet Funded with 100000 Tokens.");

        vm.stopBroadcast();
        */
    }

    function run() public {
        
        // Load deployer info
        uint256 deployerPrivateKey = vm.envUint("WALLET_DEPLOYER_PK");
        address deployer = vm.envAddress("WALLET_DEPLOYER");

        

        // =====================
        // Deployment Paramaters
        // ======================
        address _dao = vm.envAddress("TARGET_DAO"); // the DAO we want to install the plugin to
        address pluginAdmin = address(deployer);
        address reserveToken = address(rebasingReserve);
        address relayForwarder = address(0xb539068872230f20456CF38EC52EF2f91AF4AE49); //Gelato Relay
        uint initialReserve = 10 ether;  // the amunt we seeded the setup with
        uint32 reserveRatio = 300000; // initial reserve ratio
        address treasuryReceiver = _dao; // we specify the main DAO treasury as benficieary of the surplus


        // Pre-deployment check
        require((underlyingToken.balanceOf(deployer) >= 10 ether), "Deployer does not have enough underlying tokens to seed the setup with 10 tokens");

        // ======================
        // Deployment
        // ======================
        vm.startBroadcast(deployerPrivateKey);


        SymbioticBondingCurvePluginSetup bc_setup = new SymbioticBondingCurvePluginSetup();

        console.log("PluginSetup deployed to: %s", address(bc_setup));
        console.log("Plugin implementation deployed to: %s", address(bc_setup.implementation()));

        //We send enough tokens to the setup contract to initialize the bonding curve
        MockToken(underlyingToken).transfer(address(bc_setup), 10 ether); //ether used as a shorthand for 1e18
        console.log("Seeded Setup with 10 tokens for initialization");


        // We initialize the plugin and prepare the installation
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

        // ======================
        // Register Plugin
        // ======================

        PluginRepo pluginRepo = pluginRepoFactory.createPluginRepoWithFirstVersion(
                    "symbiotic-bonding-curve-1",
                    address(bc_setup),
                    deployer,
                    "0x00",
                    "0x00"
        );

        console.log("Plugin Repo created at: %s", address(pluginRepo));



        vm.stopBroadcast();
        // At this point, the missing step is for the target DAO to pass a proposal, which will execute applyInstallation() and integrate the plugin into the DAO.

    }
}
