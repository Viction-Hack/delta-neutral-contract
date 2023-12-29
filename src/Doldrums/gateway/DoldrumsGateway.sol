// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IERC20} from "lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {IGateway} from "../../../src/Doldrums/interfaces/IGateway.sol";
import "../../../src/Doldrums/gateway/GatewayV1.sol";

contract DoldrumsGateway is Gateway, IGateway {
    uint16 public dstEid;

    constructor(uint16 _dstEid, address endPoint) Gateway(endPoint, msg.sender) {
        dstEid = _dstEid;
    }

    function openPositionFor(
        bool isShort,
        address vault,
        address receiver,
        uint256 amountIn,
        uint256 minAmountOut,
        uint256 deadline
    ) external virtual {
        bytes memory message = abi.encode(isShort, vault, receiver, amountIn, minAmountOut, deadline);
        if (isShort) {
            (, bytes memory data) = vault.call(abi.encodeWithSignature("underlying()"));
            address underlying = abi.decode(data, (address));
            IERC20(underlying).transferFrom(vault, address(this), amountIn);
        }
        send(dstEid, message);
    }

    function receiveMessage(bytes memory message) public virtual override {
        MessageInfo memory messageInfo = abi.decode(message, (MessageInfo));

        uint256 transferAmount;
        if (messageInfo.success) {
            transferAmount = messageInfo.isShort ? messageInfo.remainAmount : messageInfo.executedAmountOut;
        } else {
            transferAmount = messageInfo.isShort ? messageInfo.amountIn : 0;
        }

        if (transferAmount > 0) {
            (, bytes memory data) = messageInfo.vault.call(abi.encodeWithSignature("underlying()"));
            address underlying = abi.decode(data, (address));
            (, data) = messageInfo.vault.call(abi.encodeWithSignature("controller()"));
            address controller = abi.decode(data, (address));
            IERC20(underlying).transfer(controller, transferAmount);
        }

        messageInfo.vault.call(
            abi.encodeWithSignature(
                "receivePerpOrder(bool,bool,address,uint256,uint256,uint256,uint256,uint256)",
                messageInfo.success,
                messageInfo.isShort,
                messageInfo.receiver,
                messageInfo.executedAmountOut,
                messageInfo.amountIn,
                messageInfo.remainAmount,
                messageInfo.executedPrice,
                messageInfo.executedFee
            )
        );
    }
}
