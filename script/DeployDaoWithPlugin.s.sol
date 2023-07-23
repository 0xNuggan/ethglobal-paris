// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import "forge-std/Test.sol";
import "forge-std/console.sol";

import {SymbioticBondingCurvePluginSetup} from "../src/SymbioticBondingCurvePluginSetup.sol";
import {SymbioticBondingCurvePlugin} from "../src/SymbioticBondingCurvePlugin.sol";
import {MockLSD} from "../src/mockContracts/MockLSD.sol";
import {MockToken} from "../src/mockContracts/MockToken.sol";
import {PluginSetup, IPluginSetup} from '@aragon/osx/framework/plugin/setup/PluginSetup.sol';

import {DAO, IDAO} from '@aragon/osx/core/dao/DAO.sol';
import '@aragon/osx/framework/dao/DAOFactory.sol';

contract DaoPluginScript is Script {

    uint256 deployerPrivateKey = vm.envUint("WALLET_DEPLOYER_PK");
    address deployer = vm.envAddress("WALLET_DEPLOYER");


    MockToken underlyingToken = MockToken(vm.envAddress("UNDERLYING_TOKEN")); 
    MockLSD rebasingReserve = MockLSD(vm.envAddress("RESERVE_TOKEN"));

    DAOFactory daoFactory = DAOFactory(vm.envAddress("DAO_FACTORY"));
    PluginRepo pluginRepo = PluginRepo(vm.envAddress("PLUGIN_REPO"));

    function setUp() public {
    }



    function run() public {
        console.log("start");
        DAOFactory.DAOSettings memory _daoSettings = generateDAOSettings();
        console.log("DAO Settings generated");
        DAOFactory.PluginSettings[] memory _pluginSettings = generatePluginSettings();
        console.log("Plugin Settings generated");


        DAO createdDAO =  daoFactory.createDao(_daoSettings, _pluginSettings);
        // TODO: breaks here because of version Hash error. need to debug
        console.log("DAO deployed to: %s", address(createdDAO));
    }

    function generateDAOSettings() internal  returns( DAOFactory.DAOSettings memory){
        DAOFactory.DAOSettings memory _daoSettings;
        _daoSettings.trustedForwarder = address(0xb539068872230f20456CF38EC52EF2f91AF4AE49); // Gelato Relay
        _daoSettings.daoURI = "";
        _daoSettings.subdomain = "";
        _daoSettings.metadata = bytes("0x0");
        return _daoSettings;
    }

    function generatePluginSettings() internal view returns(DAOFactory.PluginSettings[] memory){
        DAOFactory.PluginSettings[] memory _pluginSettings = new DAOFactory.PluginSettings[](1);
        _pluginSettings[0].pluginSetupRef.versionTag = generateTag();
        _pluginSettings[0].pluginSetupRef.pluginSetupRepo = pluginRepo;
        _pluginSettings[0].data = abi.encode(
                address(deployer),  
                address(rebasingReserve),  
                address(0xb539068872230f20456CF38EC52EF2f91AF4AE49), 
                10 ether,
                300000,
                address(0x0)
            );

        return _pluginSettings;

    }

    function generateTag() internal pure returns(PluginRepo.Tag memory) {
        PluginRepo.Tag memory _tag;
        _tag.release = 0;
        _tag.build = 1;
        return _tag;
    }
}
