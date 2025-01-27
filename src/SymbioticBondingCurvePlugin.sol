// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity 0.8.17;

import "forge-std/console.sol";


import {Clones} from "@openzeppelin/contracts/proxy/Clones.sol";
import {ERC165Upgradeable} from "@openzeppelin/contracts-upgradeable/utils/introspection/ERC165Upgradeable.sol";
import {IERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

import {IDAO} from "@aragon/osx/core/dao/IDAO.sol";
import {PluginUUPSUpgradeable} from "@aragon/osx/core/plugin/PluginUUPSUpgradeable.sol";
import {PluginCloneable, IDAO} from '@aragon/osx/core/plugin/PluginCloneable.sol';
import {IERC20MintableUpgradeable} from "@aragon/osx/token/ERC20/IERC20MintableUpgradeable.sol";
import {createERC1967Proxy} from "@aragon/osx/utils/Proxy.sol";

import {BaseRelayRecipient} from '@opengsn/contracts/src/BaseRelayRecipient.sol';

import {ContextUpgradeable} from '@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol';

import "./bonding_curve/ContinuousToken.sol";
import {MockLSD} from "./mockContracts/MockLSD.sol";

contract SymbioticBondingCurvePlugin is PluginCloneable, ContinuousToken, BaseRelayRecipient {
  /// @notice The ID of the permission required to call the `execute` function.
  bytes32 public constant ADMIN_EXECUTE_PERMISSION_ID = keccak256('ADMIN_EXECUTE_PERMISSION');



    address public admin;

    mapping(address => uint) public userLockedBalance;
    uint256 internal reserve;

    MockLSD public reserveToken;
    address public  treasuryAddress;
    
    //percentage for the treasury, as a number between 0 and 10000
    uint public taxPct;


    /// @notice Initializes the contract.
    /// @param _dao The associated DAO.
    /// @param _admin The address of the admin.
    function initialize(IDAO _dao, address _admin, address relayForwarder, address _reserveToken, uint _initialReserve, uint32 _reserveRatio, address _treasuryAddress) external initializer {
        __PluginCloneable_init(_dao);
        _setTrustedForwarder(relayForwarder);
        __ContinuousToken__initialize(_initialReserve, _reserveRatio);

        admin = _admin;
        treasuryAddress = _treasuryAddress;


        //TODO adapt to new token structure

        reserve = _initialReserve;
        reserveToken = MockLSD(_reserveToken);
        //we allow the reserveToken to pull the underlying from this contract
        reserveToken.underlyingToken().approve(address(reserveToken), type(uint).max);
        
        //we bring in the initial reserve to start the bonding curve
        //reserveToken.underlyingToken().transferFrom(_msgSender(), address(this), _initialReserve);

        //we are assuming the underlying token is already in the contract
        uint _initialDeposit = reserveToken.deposit(address(this), _initialReserve);
        userLockedBalance[_msgSender()] = userLockedBalance[_msgSender()] + (_initialDeposit);
    }



  
    constructor() ContinuousToken("SymbioticBondingCurvePlugin", "SBC") {
    }

    function mint(uint _amount) public returns(uint) {
        userLockedBalance[_msgSender()] = userLockedBalance[_msgSender()] + _amount;

        //we pull the protocol tokens from the user and deposit them into the staking system
        reserveToken.underlyingToken().transferFrom(_msgSender(), address(this), _amount);
        reserveToken.deposit(address(this), _amount);

        //we mint the DAO tokens
        uint amountMinted = _continuousMint(_amount);
        reserve = reserve + (_amount);
        return amountMinted;
    }

    function burn(uint _amount) public returns(uint) {
        // We calculate the amount of tokens the user will get back
        uint refundAmount = _continuousBurn(_amount);
        userLockedBalance[_msgSender()] = userLockedBalance[_msgSender()] - (refundAmount);
        reserve = reserve - (refundAmount);

         //we unstake those tokens
        reserveToken.withdraw(address(this), refundAmount);

        // we transfer them back to the user
        reserveToken.underlyingToken().transfer(_msgSender(), refundAmount); 

        return refundAmount;
    }

    function reserveBalance() override public view returns (uint) {
        return reserve;
    }  

    function reserveSurplus() public view returns (uint) {
        return reserveToken.balanceOf(address(this)) - reserve;
    }  

    // ==================
    // Main Event: Ways to deal with with the staking rewards
    // ==================
    function manageYieldSurplus(uint mode) public {
        uint surplus = reserveSurplus();

        // Option 1 : 
        // Send surplus to treasury. Most straightforward option, generates a cash flow for the DAO
        if(mode == 1){
            

         //we redeem the tokens
        reserveToken.withdraw(address(this), surplus);

        // we transfer them back to the treasury
        reserveToken.underlyingToken().transfer(treasuryAddress, surplus); 
        }

        // Option 2: 
        // Buy tokens and burn them. This effectively locks tokens in the curve forever, which will generate yield that is claimable in mode 1.
        // Also, it enforces floor price below which the token cannot go. More effective than regular token burns.
        if(mode == 2 ){

            // we update the internal accounting
            userLockedBalance[address(this)] = userLockedBalance[address(this)] + surplus;
            

            //(taken over for the ContinuousToken.mint() function)
            uint rewardAmount = getContinuousMintReward(surplus);
            _mint(address(this), rewardAmount);
            emit Minted(address(this), rewardAmount, surplus);

            // update the reserve
            reserve = reserve + (surplus);

            //burn the received tokens: now the balance is locked and we have a price floor.
            _transfer(address(this), address(0xdeadbeef), rewardAmount);

        }

        // Option 3: 
        // Modify curve shape. Since the reserve ratio is a dependent on the total supply and the underlying reserve, if we increase the reserve without minting
        // we are efectively increasing the reserve ratio, which will make flatten the curve. This will make the token more stable over time
        if (mode == 3) {
            reserve = reserveToken.balanceOf(address(this)) ;
            uint supply = totalSupply();
            uint32 newReserveRatio = calculateReserveRatio(supply, reserve);
            updateReserveRatio(newReserveRatio);
        }

    }

    function calculateReserveRatio(uint _supply, uint _reserve) public view returns (uint32) {

        // TODO: actual math. This is just a mock
        uint32 newReserveRatio = reserveRatio + uint32((_supply + _reserve) % 10000);
        return newReserveRatio;
    }



    // Implemetn Relay to allow for gasless transactions
    function _msgSender()
        internal
        view
        virtual
        override(Context, ContextUpgradeable, BaseRelayRecipient)
        returns (address)
    {
        return BaseRelayRecipient._msgSender();
    }

    function _msgData()
        internal
        view
        virtual
        override(Context, ContextUpgradeable, BaseRelayRecipient)
        returns (bytes calldata)
    {
        return BaseRelayRecipient._msgData();
    }
}

 

