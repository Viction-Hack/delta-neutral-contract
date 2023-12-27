// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IERC20} from "lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {IGateway} from "../../../src/Doldrums/interfaces/IGateway.sol";
import {IMockPerpDex} from "../../../src/Doldrums/interfaces/IMockPerpDex.sol";

contract MockPerpDexGateway is IGateway {
    address public doldrumsGateway;
    address public perpDex;

    constructor(address _doldrumsGateway, address _perpDex) {
        doldrumsGateway = _doldrumsGateway;
        perpDex = _perpDex;
    }

    function receiveMessage(bytes memory message) external {
        (bool isShort, address vault, address receiver, uint256 amountIn, uint256 minAmountOut, uint256 deadline) =
            abi.decode(message, (bool, address, address, uint256, uint256, uint256));
        (bool success, bytes memory data) = perpDex.call(
            abi.encodeWithSignature(
                "openPositionFor(bool,address,address,uint256,uint256,uint256)",
                isShort,
                vault,
                receiver,
                amountIn,
                minAmountOut,
                deadline
            )
        );


        IMockPerpDex.PositionInfo memory positionInfo;

        if (success) {
            positionInfo = abi.decode(data, (IMockPerpDex.PositionInfo));
        }

        uint256 transferAmount;
        if (success) {
            transferAmount = positionInfo.isShort ? positionInfo.remainAmount : positionInfo.executedAmountOut;
        } else {
            transferAmount = positionInfo.isShort ? amountIn : 0;
        }

        if (transferAmount > 0) {
            (, data) = positionInfo.vault.call(abi.encodeWithSignature("underlying()"));
            address underlying = abi.decode(data, (address));
            IERC20(underlying).transfer(doldrumsGateway, transferAmount);
        }

        bytes memory message = abi.encode(
            success,
            positionInfo.isShort,
            positionInfo.vault,
            positionInfo.receiver,
            positionInfo.executedAmountOut,
            positionInfo.amountIn,
            positionInfo.remainAmount,
            positionInfo.executedPrice,
            positionInfo.executedFee
        );
        doldrumsGateway.call(abi.encodeWithSignature("receiveMessage(bytes)", message));
    }
}
