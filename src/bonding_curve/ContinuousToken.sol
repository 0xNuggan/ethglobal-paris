pragma solidity 0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

import "./curves/BancorBondingCurve.sol";


abstract contract ContinuousToken is Ownable, ERC20, BancorBondingCurve {


    event Minted(address sender, uint amount, uint deposit);
    event Burned(address sender, uint amount, uint refund);

    constructor(
        string memory _name,
        string memory _symbol
    )  ERC20(_name, _symbol) BancorBondingCurve(300000) { //default value, will be overwritten
    }

    // Note: since this is internal now, it depends on the inheriting plugin to call it on initialization
    function __ContinuousToken__initialize(uint _initialSupply, uint32 _reserveRatio) internal {
        updateReserveRatio(_reserveRatio);
        _mint(_msgSender(), _initialSupply);

    }

    function continuousSupply() override public view returns (uint) {
        return totalSupply(); // Continuous Token total supply
    }

    function _continuousMint(uint _deposit) internal returns (uint) {
        require(_deposit > 0, "Deposit must be non-zero.");

        uint rewardAmount = getContinuousMintReward(_deposit);
        _mint(_msgSender(), rewardAmount);
        emit Minted(_msgSender(), rewardAmount, _deposit);
        return rewardAmount;
    }

    function _continuousBurn(uint _amount) internal returns (uint) {
        require(_amount > 0, "Amount must be non-zero.");
        require(balanceOf(_msgSender()) >= _amount, "Insufficient tokens to burn.");

        uint refundAmount = getContinuousBurnRefund(_amount);
        _burn(_msgSender(), _amount);
        emit Burned(_msgSender(), _amount, refundAmount);
        return refundAmount;
    }

    function sponsoredBurn(uint _amount) public {
        _burn(_msgSender(), _amount);
        emit Burned(_msgSender(), _amount, 0);
    }   
}