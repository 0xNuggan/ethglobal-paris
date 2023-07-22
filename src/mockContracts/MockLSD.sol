// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity ^0.8.0;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract MockLSD is ERC20 {

    ERC20 public underlyingToken;

    constructor(string memory _name, string memory _symbol, address _underlyingToken)
        ERC20(_name, _symbol)
    {
        underlyingToken = ERC20(_underlyingToken);
    }

    function deposit(address from, uint amount) public returns(uint received){
        underlyingToken.transferFrom(from, address(this), amount);
        _mint(from, amount);
        return received;

    }

    function withdraw(address to, uint amount) public {
        _burn(to, amount);
        underlyingToken.transfer(to, amount);
    }

    function mint(address to, uint value) public {
        _mint(to, value);
    }

    function burn(address from, uint value) public {
        _burn(from, value);
    }

    function simulateRebase(address to, uint value) public {
        _mint(to, value);
    }
}