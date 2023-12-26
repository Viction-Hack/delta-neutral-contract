// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IGateway {
    struct MessageInfo {
        bool success;
        bool isShort;
        address vault;
        address receiver;
        uint256 executedAmountOut;
        uint256 amountIn;
        uint256 remainAmount;
        uint256 executedPrice;
        uint256 executedFee;
    }
}
