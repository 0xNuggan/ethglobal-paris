// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/SymbioticBondingCurvePlugin.sol";
import "../src/mockContracts/MockLSD.sol";
import "../src/mockContracts/MockToken.sol";

import {Clones} from '@openzeppelin/contracts/proxy/Clones.sol';

contract SymbioticBondingCurvePluginTest is Test {
    using Clones for address;

    SymbioticBondingCurvePlugin plugin;
    MockLSD reserveToken;
    MockToken underlyingToken;

    address constant BOB = address(0xb0b);
    address constant TREASURY = address(0x123456789);
    

    function setUp() public {

        //setup mock data

        IDAO _dao = IDAO(address(this));
        address _admin = address(this);
        address _relayForwarder = address(0xf00);

        uint initialReserve = 100 ether;

        underlyingToken = new MockToken("Protocol Token", "PT");
        reserveToken = new MockLSD("LSD", "LSD", address(underlyingToken));

     

        // create plugin

        address symbioticBondingCurvePluginImplementation = address(new SymbioticBondingCurvePlugin());
        plugin = SymbioticBondingCurvePlugin(symbioticBondingCurvePluginImplementation.clone());

        underlyingToken.mint(address(plugin), initialReserve);

        //reserveToken.approve(address(plugin), type(uint).max);
        plugin.initialize(_dao, _admin, _relayForwarder, address(reserveToken), initialReserve, 300000, TREASURY);
    }

    function testSetup() public {
        assertEq(plugin.reserveBalance(), 100 ether);
        assertEq(address(plugin.reserveToken()), address(reserveToken));
        assertEq(plugin.reserveRatio(),300000 );
    }

    function testMint() public {

      
        //state before
        uint supplyBefore = plugin.totalSupply();
        uint reserveBefore = plugin.reserveBalance();

        uint receivedToken =  userDeposit(BOB, 1 ether);

        assertEq(plugin.totalSupply(), receivedToken+supplyBefore);
        assertEq(plugin.reserveBalance(), (reserveBefore + 1 ether));
        assertEq(reserveToken.balanceOf(BOB), 0 ether);
    }

    function testBurn() public {


        //state before
        uint supplyBefore = plugin.totalSupply();
        uint reserveBefore = plugin.reserveBalance();
       

        // STEP ONE: mint tokens

        uint receivedToken =  userDeposit(BOB, 1 ether);


        // STEP TWO: burn tokens
        
        vm.startPrank(BOB);
        uint receivedBack = plugin.burn(receivedToken);
        vm.stopPrank();


        //STEP THREE: everything stayed the same

        assertApproxEqAbs(plugin.totalSupply(), supplyBefore, 100);
        assertApproxEqAbs(plugin.reserveBalance(), (reserveBefore), 100);
        assertApproxEqAbs(receivedBack, 1 ether, 100);
        assertApproxEqAbs(underlyingToken.balanceOf(BOB), 1 ether, 100);
    }


    function testMockRebase() public {


        //state before
        uint supplyBefore = plugin.totalSupply();
        uint reserveBefore = plugin.reserveBalance();

        uint mintAmount = 10 ether;

       

        // STEP ONE: mint tokens
       uint receivedToken =  userDeposit(BOB, mintAmount);

        // STEP TWO: rebase
        reserveToken.simulateRebase(address(plugin), 1 ether);

        // STEP THREE: check state

        assertEq(plugin.totalSupply(), receivedToken+supplyBefore);
        assertEq(reserveToken.balanceOf(BOB), 0 ether);

        // This is the mismatch we are looking to use
        assertEq(reserveToken.balanceOf(address(plugin)), (reserveBefore + mintAmount + 1 ether));
        assertEq(plugin.reserveBalance(), (reserveBefore + mintAmount));

 
    }

    function testUseSurplusForTreasury() public {


        //state before
        uint supplyBefore = plugin.totalSupply();
        uint reserveBefore = plugin.reserveBalance();

        uint mintAmount = 10 ether;

       

        // STEP ONE: mint tokens
       uint receivedToken =  userDeposit(BOB, mintAmount);

        // STEP TWO: rebase
        reserveToken.simulateRebase(address(plugin), 1 ether);

        // STEP THREE: send rebase surplus to treasury
        plugin.manageYieldSurplus(1);

        // STEP FOUR: check state

        assertEq(plugin.totalSupply(), receivedToken+supplyBefore);
        assertEq(reserveToken.balanceOf(BOB), 0 ether);

        // The extra ether is now in the treasury
        assertEq(reserveToken.balanceOf(address(plugin)), plugin.reserveBalance());
        assertEq(plugin.reserveBalance(), (reserveBefore + mintAmount));
        assertEq(reserveToken.underlyingToken().balanceOf(plugin.treasuryAddress()), 1 ether);


    }

    function testUseSurplusToMintAndBurn() public {

        uint mintAmount = 10 ether;


        // STEP ONE: mint tokens
        userDeposit(BOB, mintAmount);

        //state before
        uint supplyBefore = plugin.totalSupply();

        // STEP TWO: rebase
        reserveToken.simulateRebase(address(plugin), 1 ether);

        // virtual balance and actual balance diverge
        assertNotEq(reserveToken.balanceOf(address(plugin)), plugin.reserveBalance());

        // we check how many tokens the surplus would generate:
        uint burnAmount = plugin.getContinuousMintReward(1 ether);

        // STEP THREE: use rebaseSurplus to mint Tokens and burn them
        plugin.manageYieldSurplus(2);

        // STEP FOUR: check state

        assertEq(plugin.totalSupply(), supplyBefore+burnAmount);

        // the reserve is in line again
        assertEq(reserveToken.balanceOf(address(plugin)), plugin.reserveBalance());


    }

    function testUseSurplusToChangeShape() public {

        uint mintAmount = 10 ether;


        // STEP ONE: mint tokens
        userDeposit(BOB, mintAmount);


        // STEP TWO: rebase
        reserveToken.simulateRebase(address(plugin), 1 ether);

        uint reservRatioBefore = plugin.reserveRatio();

        // STEP THREE: use rebaseSurplus to change shape
        plugin.manageYieldSurplus(3);

        // STEP FOUR: the reserve ratio has been updated:
         assertNotEq(0, plugin.reserveRatio());
        assertNotEq(reservRatioBefore, plugin.reserveRatio());

        // it does not break with the new ReserveRatio
       testBurn();



    }


    // helper functions
    function userDeposit(address _user, uint _amount) internal returns (uint amountReceived){
        underlyingToken.mint(_user, _amount);

        vm.startPrank(_user);
        underlyingToken.approve(address(plugin), type(uint).max);
        uint receivedToken = plugin.mint(_amount);
        vm.stopPrank();

        return receivedToken;
    }

}