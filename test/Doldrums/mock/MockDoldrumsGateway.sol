// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IERC20} from "lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {IGateway} from "../../../src/Doldrums/interfaces/IGateway.sol";
import "../../../src/Doldrums/gateway/Gateway.sol";

contract MockDoldrumsGateway is Gateway, IGateway {
    uint32 public constant dstEid = 10231;
    // address public constant endPoint = 0xae92d5aD7583AD66E49A0c67BAd18F6ba52dDDc1;
    address public perpDexGateway;

    constructor(address endPoint) Gateway(endPoint, msg.sender) {}

    function setPerpDexGateway(address _perpDexGateway) external {
        perpDexGateway = _perpDexGateway;
    }

    function openPositionFor(
        bool isShort,
        address vault,
        address receiver,
        uint256 amountIn,
        uint256 minAmountOut,
        uint256 deadline
    ) external {
        bytes memory message = abi.encode(isShort, vault, receiver, amountIn, minAmountOut, deadline);
        if (isShort) {
            (, bytes memory data) = vault.call(abi.encodeWithSignature("underlying()"));
            address underlying = abi.decode(data, (address));
            IERC20(underlying).transferFrom(vault, address(this), amountIn);
        }
        // perpDexGateway.call(abi.encodeWithSignature("receiveMessage(bytes)", message));
        send(dstEid, message);
    }

    function _lzReceive(
        Origin calldata _origin, // struct containing info about the message sender
        bytes32 _guid, // global packet identifier
        bytes calldata payload, // encoded message payload being received
        address _executor, // the Executor address.
        bytes calldata _extraData // arbitrary data appended by the Executor
    ) internal override {
        receiveMessage(payload);
    }

    function receiveMessage(bytes memory message) public {
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
