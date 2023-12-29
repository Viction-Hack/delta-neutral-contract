// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IERC20} from "lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {Origin} from "@layerzerolabs/lz-evm-protocol-v2/contracts/interfaces/ILayerZeroReceiver.sol";
import "../../../src/Doldrums/gateway/PerpDexGateway.sol";

contract MockPerpDexGateway is PerpDexGateway {
    address public doldrumsGateway;

    constructor(uint16 _dstEid, address endPoint, address _perpDex) PerpDexGateway(_dstEid, endPoint, _perpDex) {}

    function setDoldrumsGateway(address _doldrumsGateway) external {
        doldrumsGateway = _doldrumsGateway;
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
        send(dstEid, message);
    }
}
