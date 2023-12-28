// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IMockPerpDex {
    event PositionExecuted(PositionInfo positionInfo);

    error DeadlineError(uint256 deadline, uint256 timestamp);
    error MinAmountOutError(uint256 minAmountOut, uint256 executedAmountOut);

    struct Position {
        int256 amount;
        uint256 entryPrice;
    }

    struct PositionInfo {
        bool isShort;
        address vault;
        address receiver;
        uint256 executedAmountOut;
        uint256 amountIn;
        uint256 remainAmount;
        uint256 executedPrice;
        uint256 executedFee;
    }

    function openPositionFor(
        bool isShort,
        address vault,
        address receiver,
        uint256 amountIn,
        uint256 minAmountOut,
        uint256 deadline
    ) external returns (PositionInfo memory);
    function changeOraclePrice(address vault, uint256 newPrice) external;
    function getPosition(address account) external view returns (Position memory);
}
