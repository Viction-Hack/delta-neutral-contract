// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IMockPerpDex} from "../interfaces/IMockPerpDex.sol";
import {Vault} from "../vault/Vault.sol";

/**
 * @title MockPerpDex
 * This is a mock contract for PerpDex to be used in testing environments.
 */
contract MockPerpDex is IMockPerpDex {
    mapping(address => Position) positions; // Mapping of positions
    mapping(address => uint256) public priceOracle; // Vault Address => Price of the asset in USD

    /**
     * @dev Simulates opening a position on a perpetual dex and then calls the receivePerpOrder function on the Vault.
     * @param vault Address of the vault contract initiating the open position.
     * @param receiver Address of the receiver for the position.
     * @param amountIn Amount of the asset being used.
     * @param minAmountOut Minimum amount out expected from the operation.
     * @param deadline Deadline for the operation.
     * @param isShort Boolean indicating if the position is short or not.
     */
    function openPositionFor(
        bool isShort,
        address vault,
        address receiver,
        uint256 amountIn,
        uint256 minAmountOut,
        uint256 deadline
    ) external returns (PositionInfo memory) {
        if (deadline <= block.timestamp) {
            revert DeadlineError(deadline, block.timestamp);
        }

        uint256 price = priceOracle[vault];
        Position storage position = positions[vault];

        PositionInfo memory positionInfo = PositionInfo(isShort, vault, receiver, 0, amountIn, 0, 0, 0);

        positionInfo.remainAmount = amountIn * 2 / 1000; // 0.2% slippage
        uint256 executedAmount;
        int256 newNetValue;

        amountIn -= positionInfo.remainAmount;

        if (isShort) {
            // short with collateral
            positionInfo.executedPrice = price * 98 / 100; // 2% slippage
            positionInfo.executedFee = amountIn / 1000; // 0.1% fee
            executedAmount = amountIn - positionInfo.executedFee;
            positionInfo.executedAmountOut = executedAmount * positionInfo.executedPrice / 10 ** 8; // amount is usd
            newNetValue = position.amount * int256(position.entryPrice) - int256(positionInfo.executedAmountOut);
            position.amount -= int256(executedAmount);
            position.entryPrice = uint256(newNetValue / position.amount);
        } else {
            // stop with usd
            positionInfo.executedPrice = price * 102 / 100; // 2% slippage
            positionInfo.executedFee = amountIn / 1000; // 0.1% fee
            executedAmount = amountIn - positionInfo.executedFee;
            positionInfo.executedAmountOut = executedAmount * 10 ** 8 / positionInfo.executedPrice; // amount is collateral
            newNetValue = position.amount * int256(position.entryPrice) + int256(executedAmount);
            position.amount += int256(positionInfo.executedAmountOut);
            position.entryPrice = uint256(newNetValue / position.amount);
        }

        if (positionInfo.executedAmountOut < minAmountOut) {
            revert MinAmountOutError(minAmountOut, positionInfo.executedAmountOut);
        }

        emit PositionExecuted(positionInfo);
        return positionInfo;
    }

    /**
     * @dev Changes the oracle price to the specified value.
     * @param vault Address of the vault to change the price of.
     * @param newPrice The new price to be set.
     */
    function changeOraclePrice(address vault, uint256 newPrice) external {
        priceOracle[vault] = newPrice;
    }

    /**
     * @dev Returns the position of the specified address.
     * @param account Address of the account to get the position of.
     * @return The position of the account.
     */
    function getPosition(address account) external view returns (Position memory) {
        return positions[account];
    }
}
