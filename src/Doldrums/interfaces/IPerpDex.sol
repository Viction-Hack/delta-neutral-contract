// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;


interface IPerpDex {

        function openPositionFor(
            address vault,
            address receiver,
            uint256 amount,
            uint256 minAmountOut,
            uint256 deadline,
            bool isShort
        ) external;
    
}