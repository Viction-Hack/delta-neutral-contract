// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Vault} from "../vault/Vault.sol";

/**
 * @title MockPerpDex
 * This is a mock contract for PerpDex to be used in testing environments.
 */
contract MockPerpDex {
    struct Position {
        int256 amount;
        uint256 entryPrice;
    }

    mapping(address => Position) positions; // Mapping of positions
    mapping(address => uint256) public priceOracle; // Vault Address => Price of the asset in USD

    /**
     * @dev Simulates opening a position on a perpetual dex and then calls the receivePerpOrder function on the Vault.
     * @param vault Address of the vault contract initiating the open position.
     * @param receiver Address of the receiver for the position.
     * @param amount Amount of the asset being used.
     * @param minAmountOut Minimum amount out expected from the operation.
     * @param deadline Deadline for the operation.
     * @param isShort Boolean indicating if the position is short or not.
     */
    function openPositionFor(
        address vault,
        address receiver,
        uint256 amount,
        uint256 minAmountOut,
        uint256 deadline,
        bool isShort
    ) external {
        // Check if the deadline has passed
        bool success = deadline > block.timestamp;
        uint256 price = priceOracle[vault];

        // Calculate the executed amounts
        uint256 executedAmountOut = amount * price * 98 / 100; // 2% slippage
        uint256 executedPrice = price;
        uint256 executedFee = amount * price / 1000; // 0.1% fee
        uint256 remainingAmount = amount * price - executedAmountOut - executedFee;

        if (executedAmountOut < minAmountOut) {
            success = false;
        }

        if (success) {
            Position storage position = positions[receiver];
            int256 newTotalValue = int256(amount * price) + int256(position.entryPrice) * position.amount;

            if (isShort) {
                position.amount -= int256(amount);
            } else {
                position.amount += int256(amount);
            }

            position.entryPrice = uint256(newTotalValue / position.amount);
        }

        // Vault(vault).receivePerpOrder(
        //     success, isShort, receiver, executedAmountOut, amount, remainingAmount, executedPrice, executedFee
        // );
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