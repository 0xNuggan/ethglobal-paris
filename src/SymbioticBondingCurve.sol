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

import {ContextUpgradeable} from '@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol';

import "./bonding_curve/ContinuousToken.sol";

contract SymbioticBondingCurvePlugin is PluginCloneable, ContinuousToken {
  /// @notice The ID of the permission required to call the `execute` function.
  bytes32 public constant ADMIN_EXECUTE_PERMISSION_ID = keccak256('ADMIN_EXECUTE_PERMISSION');



    address public admin;

    mapping(address => uint) public userLockedBalance;
    uint256 internal reserve;

    ERC20 public reserveToken;
    address public  treasuryAddress;
    
    //percentage for the treasury, as a number between 0 and 10000
    uint public taxPct;


    /// @notice Initializes the contract.
    /// @param _dao The associated DAO.
    /// @param _admin The address of the admin.
    function initialize(IDAO _dao, address _admin, address _reserveToken, uint _initialReserve, uint32 _reserveRatio, address _treasuryAddress) external initializer {
        __PluginCloneable_init(_dao);
        __ContinuousToken__initialize(_initialReserve, _reserveRatio);

        admin = _admin;
        treasuryAddress = _treasuryAddress;

        

        reserve = _initialReserve;
        reserveToken = ERC20(_reserveToken);
        reserveToken.transferFrom(_msgSender(), address(this), _initialReserve);
        userLockedBalance[_msgSender()] = userLockedBalance[_msgSender()] + (_initialReserve);
    }



  
    constructor() ContinuousToken("SymbioticBondingCurvePlugin", "SBC") {
        // for the burning later
        approve(address(this), type(uint).max);
    }

    function mint(uint _amount) public returns(uint) {
        userLockedBalance[_msgSender()] = userLockedBalance[_msgSender()] + _amount;
        reserveToken.transferFrom(_msgSender(), address(this), _amount);
        uint amountMinted = _continuousMint(_amount);
        reserve = reserve + (_amount);
        return amountMinted;
    }

    function burn(uint _amount) public returns(uint) {
        uint refundAmount = _continuousBurn(_amount);
        userLockedBalance[_msgSender()] = userLockedBalance[_msgSender()] - (refundAmount);
        reserve = reserve - (refundAmount);
        reserveToken.transfer(_msgSender(), refundAmount);
        return refundAmount;
    }

    function reserveBalance() override public view returns (uint) {
        return reserve;
    }  

    function reserveSurplus() public view returns (uint) {
        return reserveToken.balanceOf(address(this)) - reserve;
    }  

    function manageYieldSurplus(uint mode) public {
        uint surplus = reserveSurplus();

        // mode 1 : surplus to treasury
        if(mode == 1){
            
            reserveToken.transfer(treasuryAddress, surplus);
        }
        // mode 2: increase price floor:
        if(mode == 2 ){

            // we update the internal accounting
            userLockedBalance[address(this)] = userLockedBalance[address(this)] + surplus;
            

            //(taken for the ContinuousToken mint function)
            uint rewardAmount = getContinuousMintReward(surplus);
            _mint(address(this), rewardAmount);
            emit Minted(address(this), rewardAmount, surplus);

            // update the reserve
            reserve = reserve + (surplus);

            //burn the received tokens: now the balance is locked and effectively raises the price floor.
            _transfer(address(this), address(0xdeadbeef), rewardAmount);

        }

        // mode 3: modify curve shape
        if (mode == 3) {
            reserve = reserveToken.balanceOf(address(this)) ;
            uint supply = totalSupply();
            uint32 newReserveRatio = calculateReserveRatio(supply, reserve);
            updateReserveRatio(newReserveRatio);
        }

    }

    function calculateReserveRatio(uint _supply, uint _reserve) public view returns (uint32) {

        // TODO: actual math
        uint32 newReserveRatio = uint32((_supply + _reserve) % 1000000);
        //console.logUint(newReserveRatio);
        return newReserveRatio;
    }



// housekeeping 
 function _msgSender() internal view virtual override(Context, ContextUpgradeable) returns (address) {
        return msg.sender;
  }

    function _msgData() internal view virtual  override(Context, ContextUpgradeable)  returns (bytes calldata) {
        return msg.data;
    }
}

 

