// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;


interface IVault {

    function deposit(
        address receiver,
        uint256 collateralAmountIn,
        uint256 minDUSDCAmountOut,
        uint256 deadline
    ) payable external;

    function redeem(
        address receiver,
        uint256 dusdAmountIn,
        uint256 minCollateralAmountOut,
        uint256 deadline
    ) external;

    event PositionRequested(address indexed receiver, uint256 amount, uint256 minAmountOut, uint256 deadline, bool isShort);
    event PositionExecuted(bool indexed success, bool isShort, address indexed receiver, uint256 excutedAmountOut, uint256 orginAmountIn, uint256 remainAmount, uint256 excutedPrice, uint256 excutedFee);
}
