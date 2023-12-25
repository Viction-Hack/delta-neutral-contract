// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "./VRC25.sol";

abstract contract VRC25Gas is VRC25 {
    using SafeMath for uint256;

    uint256 private constant BASE_GAS = 49686; // base gas for gas calculation and transfer
    uint256 private constant EXTRA_GAS_FOR_FIRST_TIME = 15000 + 80; // Extra gas for first-time transfer
    uint256 private constant GAS_REFUND_FOR_EMPTYING_BALANCE = 15000 - 80; // Gas refund for emptying balance

    event GasFee(address indexed from, address indexed to, uint256 fee);

    constructor(string memory name, string memory symbol, uint8 decimal) VRC25(name,symbol,decimal) {
    }

    modifier gasCalc {
        uint256 gasBefore = gasleft();
        _;
        uint256 oraclePrice = 1;
        uint256 gasConsumed = gasBefore - gasleft();
        uint256 extraGas = estimateTransferGas(_owner,(gasConsumed + BASE_GAS) * tx.gasprice); 
        uint256 totalGas = extraGas + gasConsumed;
        uint256 gasFee = totalGas * tx.gasprice;
        uint256 convertedFee = gasFee * oraclePrice;
        _transfer(msg.sender, _owner, convertedFee);
        emit GasFee(msg.sender, _owner, convertedFee);
    }


    function estimateTransferGas(address recipient, uint256 amount) public view returns (uint256) {
        uint256 estimatedGas = BASE_GAS;

        // Check for first-time transfer (balance is zero)
        if (this.balanceOf(recipient) == 0) {
            estimatedGas += EXTRA_GAS_FOR_FIRST_TIME;
        }

        // Check for balance emptying
        if (this.balanceOf(msg.sender) == amount) {
            estimatedGas -= GAS_REFUND_FOR_EMPTYING_BALANCE;
        }
        return estimatedGas;
    }

    function transfer(address recipient, uint256 amount) external override gasCalc returns (bool) {
        uint256 fee = estimateFee(amount);
        _transfer(msg.sender, recipient, amount);
        _chargeFeeFrom(msg.sender, recipient, fee);
        return true;
    }

    function approve(address spender, uint256 amount) external override gasCalc returns (bool) {
        uint256 fee = estimateFee(0);
        _approve(msg.sender, spender, amount);
        _chargeFeeFrom(msg.sender, address(this), fee);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) virtual external override gasCalc returns (bool) {
        uint256 fee = estimateFee(amount);
        require(_allowances[sender][msg.sender] >= amount.add(fee), "VRC25: amount exeeds allowance");

        _allowances[sender][msg.sender] = _allowances[sender][msg.sender].sub(amount).sub(fee);
        _transfer(sender, recipient, amount);
        _chargeFeeFrom(sender, recipient, fee);
        return true;
    }

    function burn(uint256 amount) external override gasCalc returns (bool) {
        uint256 fee = estimateFee(0);
        _burn(msg.sender, amount);
        _chargeFeeFrom(msg.sender, address(this), fee);
        return true;
    }

}