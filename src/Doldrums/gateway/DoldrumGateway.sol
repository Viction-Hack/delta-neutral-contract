// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IERC20} from "lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {LzApp} from "@layerzerolabs/solidity-examples/contracts/lzApp/LzApp.sol";
import {IOFTV2} from "@layerzerolabs/solidity-examples/contracts/token/oft/v2/interfaces/IOFTV2.sol";
import {ICommonOFT} from "@layerzerolabs/solidity-examples/contracts/token/oft/v2/interfaces/ICommonOFT.sol";
import {Ownable} from "openzeppelin-contracts/contracts/access/Ownable.sol";
import {IGateway} from "../../../src/Doldrums/interfaces/IGateway.sol";

contract DoldrumGateway is IGateway, LzApp {
    address public perpDexGateway;
    uint16 private constant _dstChainId = 0x0001;

    constructor(address _lzEndpoint) LzApp(_lzEndpoint) Ownable(msg.sender) {}

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
        bytes memory payload = abi.encode(isShort, vault, receiver, amountIn, minAmountOut, deadline);

        bytes memory adapterParams = abi.encodePacked(uint16(1), uint256(350000));

        if (isShort) {
            (, bytes memory data) = vault.call(abi.encodeWithSignature("underlying()"));
            address underlying = abi.decode(data, (address));
            IOFTV2(underlying).sendAndCall(
                vault,
                _dstChainId,
                bytes32(bytes20(perpDexGateway)),
                amountIn,
                payload,
                uint64(0), // 수정 필요할 수도 있음
                ICommonOFT.LzCallParams(payable(msg.sender), address(0x0), adapterParams)
            );
        } else {
            // 숏 일때만 transfer 하는 거 같길래 long 일때는 payload만 send
            _lzSend(_dstChainId, payload, payable(address(this)), address(0x0), adapterParams, uint64(0));
        }
    }

    function _blockingLzReceive(uint16 _srcChainId, bytes memory _srcAddress, uint64 _nonce, bytes memory _payload)
        internal
        override
    {
        MessageInfo memory messageInfo = abi.decode(_payload, (MessageInfo));

        uint256 transferAmount;
        if (messageInfo.success) {
            transferAmount = messageInfo.isShort ? messageInfo.remainAmount : messageInfo.executedAmountOut;
        } else {
            transferAmount = messageInfo.isShort ? messageInfo.amountIn : 0;
        }

        bytes memory adapterParams = abi.encodePacked(uint16(1), uint256(350000));

        if (transferAmount > 0) {
            (, bytes memory data) = messageInfo.vault.call(abi.encodeWithSignature("underlying()"));
            address underlying = abi.decode(data, (address));
            (, data) = messageInfo.vault.call(abi.encodeWithSignature("controller()"));
            address controller = abi.decode(data, (address));
            IOFTV2(underlying).sendAndCall(
                address(this),
                _dstChainId,
                bytes32(bytes20(controller)),
                transferAmount,
                _payload,
                uint64(0),
                ICommonOFT.LzCallParams(payable(msg.sender), address(0x0), adapterParams)
            );
        }
    }
}
