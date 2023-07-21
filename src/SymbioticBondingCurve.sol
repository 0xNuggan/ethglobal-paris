// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity 0.8.17;


import {Clones} from "@openzeppelin/contracts/proxy/Clones.sol";
import {ERC165Upgradeable} from "@openzeppelin/contracts-upgradeable/utils/introspection/ERC165Upgradeable.sol";
import {IERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

import {IDAO} from "@aragon/osx/core/dao/IDAO.sol";
import {PluginUUPSUpgradeable} from "@aragon/osx/core/plugin/PluginUUPSUpgradeable.sol";
import {PluginCloneable, IDAO} from '@aragon/osx/core/plugin/PluginCloneable.sol';
import {IERC20MintableUpgradeable} from "@aragon/osx/token/ERC20/IERC20MintableUpgradeable.sol";
import {createERC1967Proxy} from "@aragon/osx/utils/Proxy.sol";

import "./bonding_curve/ContinuousToken.sol";

contract SimpleAdmin is PluginCloneable, ContinuousToken {
  /// @notice The ID of the permission required to call the `execute` function.
  bytes32 public constant ADMIN_EXECUTE_PERMISSION_ID = keccak256('ADMIN_EXECUTE_PERMISSION');

// housekeeping 
/*  function _msgSender() internal view virtual override(Context, ContextUpgradeable) returns (address) {
        return msg.sender;
  }

    function _msgData() internal view virtual  override(Context, ContextUpgradeable)  returns (bytes calldata) {
        return msg.data;
    }
 */

  address public admin;

  /// @notice Initializes the contract.
  /// @param _dao The associated DAO.
  /// @param _admin The address of the admin.
  function initialize(IDAO _dao, address _admin) external initializer {
	__PluginCloneable_init(_dao);
	admin = _admin;
  }
 uint256 internal reserve;

    mapping(address => uint) public userLockedBalance;
  
    constructor() public payable ContinuousToken("SymbioticBondingCurve", "SBC", 100 ether, 300000) {
        reserve = msg.value;
        userLockedBalance[_msgSender()] = userLockedBalance[_msgSender()] + (msg.value);
    }



    fallback() external payable { mint(); }


    receive() external payable {}

    function mint() public payable {
        uint purchaseAmount = msg.value;
        userLockedBalance[_msgSender()] = userLockedBalance[_msgSender()] + (msg.value);
        _continuousMint(purchaseAmount);
        reserve = reserve + (purchaseAmount);
    }

    function burn(uint _amount) public {
        uint refundAmount = _continuousBurn(_amount);
        userLockedBalance[_msgSender()] = userLockedBalance[_msgSender()] - (refundAmount);
        reserve = reserve - (refundAmount);
        _msgSender().transfer(refundAmount);
    }

    function reserveBalance() override public view returns (uint) {
        return reserve;
    }    
}

 

