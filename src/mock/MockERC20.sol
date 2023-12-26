// SPDX-License-Identifier: BUSL-1.1-3.0-or-later
pragma solidity ^0.8.17;

import { ERC20 } from "lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";

contract MockERC20 is ERC20 {
    uint8 private _decimals;

    constructor(string memory name, string memory symbol, uint8 decimals) ERC20(name, symbol) {
        _decimals = decimals;
    }

    function mint(address account, uint256 amount) external {
        _mint(account, amount);
    }

    function burn(address account, uint256 amount) external {
        _burn(account, amount);
    }

    function decimals() public view virtual override returns (uint8) {        
        return _decimals;
    }
}

