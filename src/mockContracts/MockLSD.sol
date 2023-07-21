// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity ^0.8.0;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract MockLSD is ERC20 {

    constructor(string memory _name, string memory _symbol)
        ERC20(_name, _symbol)
    {}

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