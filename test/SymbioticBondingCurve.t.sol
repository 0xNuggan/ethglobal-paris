// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/SymbioticBondingCurve.sol";
import "../src/mockContracts/MockLSD.sol";

import {Clones} from '@openzeppelin/contracts/proxy/Clones.sol';

contract SymbioticBondingCurvePluginTest is Test {
    using Clones for address;

    SymbioticBondingCurvePlugin plugin;
    MockLSD reserveToken;
    

    function setUp() public {

        //setup mock data

        IDAO _dao = IDAO(address(this));
        address _admin = address(this);

        uint initialReserve = 100 ether;
        reserveToken = new MockLSD("LSD", "LSD");
        reserveToken.mint(address(this), initialReserve);

        // create plugin

        address symbioticBondingCurvePluginImplementation = address(new SymbioticBondingCurvePlugin());
        plugin = SymbioticBondingCurvePlugin(symbioticBondingCurvePluginImplementation.clone());

        reserveToken.approve(address(plugin), type(uint).max);
        plugin.initialize(_dao, _admin, address(reserveToken), initialReserve, 300000);
    }

    function testSetup() public {
        assertEq(plugin.reserveBalance(), 100 ether);
        assertEq(address(plugin.reserveToken()), address(reserveToken));
    }

    function testMint() public {
        address bob = address(0x1);
        uint mintAmount = 1 ether;
        reserveToken.mint(bob, mintAmount);
       

        //state before
        uint supplyBefore = plugin.totalSupply();
        uint reserveBefore = plugin.reserveBalance();

        vm.startPrank(bob);
        reserveToken.approve(address(plugin), type(uint).max);
        plugin.mint(mintAmount);
        vm.stopPrank();

        assertEq(plugin.totalSupply(), mintAmount+supplyBefore);
        assertEq(plugin.reserveBalance(), (reserveBefore + 1 ether));
        assertEq(reserveToken.balanceOf(bob), 0 ether);
    }


}