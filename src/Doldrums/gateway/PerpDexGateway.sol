// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {LzApp} from "@layerzerolabs/solidity-examples/contracts/lzApp/LzApp.sol";
import {IOFTV2} from "@layerzerolabs/solidity-examples/contracts/token/oft/v2/interfaces/IOFTV2.sol";
import {ICommonOFT} from "@layerzerolabs/solidity-examples/contracts/token/oft/v2/interfaces/ICommonOFT.sol";
import {IGateway} from "../../../src/Doldrums/interfaces/IGateway.sol";
import {IMockPerpDex} from "../../../src/Doldrums/interfaces/IMockPerpDex.sol";
import {Ownable} from "openzeppelin-contracts/contracts/access/Ownable.sol";

contract PerpDexGateway is IGateway, LzApp {
    address public doldrumsGateway;
    address public perpDex;
    uint16 private constant _dstChainId = 0x0001;

    constructor(address _doldrumsGateway, address _perpDex, address _lzEndpoint)
        LzApp(_lzEndpoint)
        Ownable(msg.sender)
    {
        doldrumsGateway = _doldrumsGateway;
        perpDex = _perpDex;
    }

    function _blockingLzReceive(uint16 _srcChainId, bytes memory _srcAddress, uint64 _nonce, bytes memory _payload)
        internal
        override
    {
        (bool isShort, address vault, address receiver, uint256 amountIn, uint256 minAmountOut, uint256 deadline) =
            abi.decode(_payload, (bool, address, address, uint256, uint256, uint256));
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

        bytes memory payload = abi.encode(
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

        bytes memory adapterParams = abi.encodePacked(uint16(1), uint256(350000));

        if (transferAmount > 0) {
            (, data) = positionInfo.vault.call(abi.encodeWithSignature("underlying()"));
            address underlying = abi.decode(data, (address));
            IOFTV2(underlying).sendAndCall(
                address(this),
                _dstChainId,
                bytes32(bytes20(doldrumsGateway)),
                transferAmount,
                payload,
                uint64(0),
                ICommonOFT.LzCallParams(payable(msg.sender), address(0x0), adapterParams)
            );
        }
    }
}
