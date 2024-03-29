// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IERC20} from "lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {Origin} from "@layerzerolabs/lz-evm-protocol-v2/contracts/interfaces/ILayerZeroReceiver.sol";
import "../../../src/Doldrums/gateway/DoldrumsGateway.sol";

contract MockDoldrumsGateway is DoldrumsGateway {
    address public perpDexGateway;

    constructor(uint16 _dstEid, address endPoint) DoldrumsGateway(_dstEid, endPoint) {}

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
    ) external override {
        bytes memory message = abi.encode(isShort, vault, receiver, amountIn, minAmountOut, deadline);
        if (isShort) {
            (, bytes memory data) = vault.call(abi.encodeWithSignature("underlying()"));
            address underlying = abi.decode(data, (address));
            IERC20(underlying).transferFrom(vault, perpDexGateway, amountIn);
        }
        send(dstEid, message);
    }

    function send(uint16 _dstEid, bytes memory _payload) public payable override {
        // encode the adapter parameters
        uint16 version = 1;
        uint256 gasForDestinationLzReceive = 350000;
        bytes memory adapterParams = abi.encodePacked(version, gasForDestinationLzReceive);

        // (uint256 nativeFee, uint256 zroFee) =
        //     lzEndpoint.estimateFees(_dstEid, address(this), _payload, false, adapterParams);

        // send LayerZero message
        _lzSend( // {value: messageFee} will be paid out of this contract!
            _dstEid, // destination chainId
            _payload, // abi.encode()'ed bytes
            payable(this), // (msg.sender will be this contract) refund address (LayerZero will refund any extra gas back to caller of send())
            address(0x0), // future param, unused for this example
            adapterParams, // v1 adapterParams, specify custom destination gas qty
            0
        );
    }

    function lzReceive(
        bytes calldata payload // encoded message payload being received
    ) external {
        receiveMessage(payload);
    }

    function receiveMessage(bytes memory message) public override {
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
