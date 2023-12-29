// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IERC20} from "lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {IGateway} from "../../../src/Doldrums/interfaces/IGateway.sol";
import {IMockPerpDex} from "../../../src/Doldrums/interfaces/IMockPerpDex.sol";
import "../../../src/Doldrums/gateway/GatewayV1.sol";

contract PerpDexGateway is Gateway, IGateway {
    uint16 public dstEid;
    address public perpDex;

    constructor(uint16 _dstEid, address endPoint, address _perpDex) Gateway(endPoint, msg.sender) {
        dstEid = _dstEid;
        perpDex = _perpDex;
    }

    function receiveMessage(bytes memory message) public virtual override {
        (bool isShort, address vault, address receiver, uint256 amountIn, uint256 minAmountOut, uint256 deadline) =
            abi.decode(message, (bool, address, address, uint256, uint256, uint256));
        IMockPerpDex.PositionInfo memory positionInfo;
        positionInfo.isShort = isShort;
        positionInfo.vault = vault;
        positionInfo.receiver = receiver;
        positionInfo.amountIn = amountIn;

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

        if (success) {
            positionInfo = abi.decode(data, (IMockPerpDex.PositionInfo));
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
        send(dstEid, message);
    }
}
