// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IDoldrumsGateway {
    function openPositionFor(
        bool isShort,
        address vault,
        address receiver,
        uint256 amountIn,
        uint256 minAmountOut,
        uint256 deadline
    ) external;
}
