// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.9;

import "@layerzerolabs/solidity-examples/contracts/token/oft/v2/interfaces/IOFTV2.sol";

/// @title Interface for WETH9
interface INativeOFTV2 is IOFTV2 {
    /// @notice Deposit ether to get wrapped ether
    function deposit() external payable;

    /// @notice Withdraw wrapped ether to get ether
    function withdraw(address, uint256) external;
}
