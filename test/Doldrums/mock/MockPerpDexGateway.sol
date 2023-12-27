// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IERC20} from "lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {IGateway} from "../../../src/Doldrums/interfaces/IGateway.sol";
import {IMockPerpDex} from "../../../src/Doldrums/interfaces/IMockPerpDex.sol";
import "../../../src/Doldrums/gateway/Gateway.sol";

contract MockPerpDexGateway is Gateway, IGateway {
    uint32 public constant dstEid = 10196;
    // address public constant endPoint = 0x6098e96a28E02f27B1e6BD381f870F1C8Bd169d3;
    address public doldrumsGateway;
    address public perpDex;

    constructor(address endPoint, address _doldrumsGateway, address _perpDex) Gateway(endPoint, msg.sender) {
        doldrumsGateway = _doldrumsGateway;
        perpDex = _perpDex;
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

        // uint256 transferAmount;
        // if (success) {
        //     transferAmount = positionInfo.isShort ? positionInfo.remainAmount : positionInfo.executedAmountOut;
        // } else {
        //     transferAmount = positionInfo.isShort ? amountIn : 0;
        // }

        // if (transferAmount > 0) {
        //     (, data) = positionInfo.vault.call(abi.encodeWithSignature("underlying()"));
        //     address underlying = abi.decode(data, (address));
        //     IERC20(underlying).transfer(doldrumsGateway, transferAmount);
        // }

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
        // doldrumsGateway.call(abi.encodeWithSignature("receiveMessage(bytes)", message));
        send(dstEid, message);
    }
}
