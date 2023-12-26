// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Vault} from "../vault/Vault.sol";
import {LzApp} from "@layerzerolabs/solidity-examples/contracts/lzApp/LzApp.sol";
import {IOFTV2} from "@layerzerolabs/solidity-examples/contracts/token/oft/v2/interfaces/IOFTV2.sol";
import {ICommonOFT} from "@layerzerolabs/solidity-examples/contracts/token/oft/v2/interfaces/ICommonOFT.sol";
import {Ownable} from "openzeppelin-contracts/contracts/access/Ownable.sol";
import {IPerpDex} from "../interfaces/IPerpDex.sol";

contract PerpDexEntrypoint is LzApp {
    uint16 private constant _dstChainId = 0x0001;
    address public perpDex;

    constructor(address _lzEndpoint, address _perpDex, address _owner) LzApp(_lzEndpoint) Ownable(_owner) {
        perpDex = _perpDex;
    }

    function receivePerpOrder(
        address _vault,
        bool _success,
        bool _isShort,
        address _receiver,
        uint256 _excutedAmountOut,
        uint256 _orginAmountIn,
        uint256 _remainAmount,
        uint256 _excutedPrice,
        uint256 _excutedFee
    ) external {
        // Called by PerpDex
        require(msg.sender == perpDex, "PerpDexEntrypoint: not perpDex");

        bytes memory adapterParams = abi.encodePacked(uint16(1), uint256(350000));

        // encode the payload
        bytes memory payload = abi.encode(
            _vault,
            _success,
            _isShort,
            _receiver,
            _excutedAmountOut,
            _orginAmountIn,
            _remainAmount,
            _excutedPrice,
            _excutedFee
        );

        // Send to DoldrumGateway
        _lzSend(_dstChainId, payload, payable(msg.sender), address(0x0), adapterParams, uint256(0));
    }

    function _blockingLzReceive(uint16 _srcChainId, bytes memory _srcAddress, uint64 _nonce, bytes memory _payload)
        internal
        override
    {
        // Receive from DoldrumGateway
        (address vault, address receiver, uint256 amount, uint256 minAmountOut, uint256 deadline, bool isShort) =
            abi.decode(_payload, (address, address, uint256, uint256, uint256, bool));

        // Open position on PerpDex
        IPerpDex(perpDex).openPositionFor(vault, receiver, amount, minAmountOut, deadline, isShort);
    }
}
