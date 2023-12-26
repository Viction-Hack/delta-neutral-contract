// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Vault} from "../vault/Vault.sol";
import {LzApp} from "@layerzerolabs/solidity-examples/contracts/lzApp/LzApp.sol";
import {IOFTV2} from "@layerzerolabs/solidity-examples/contracts/token/oft/v2/interfaces/IOFTV2.sol";
import {ICommonOFT} from "@layerzerolabs/solidity-examples/contracts/token/oft/v2/interfaces/ICommonOFT.sol";
import {Ownable} from "openzeppelin-contracts/contracts/access/Ownable.sol";

contract PerpDexEntrypoint is LzApp {
    uint16 private constant _dstChainId = 0x0001;

    constructor(address _lzEndpoint, address _owner) LzApp(_lzEndpoint) Ownable(_owner) {}

    function openPositionFor(
        address _vault,
        address _receiver,
        uint256 _collateralAmountIn,
        uint256 _minDUSDCAmountOut,
        uint256 _deadline,
        bool _short
    ) external {
        // Called by Vault
        require(msg.sender == _vault, "PerpDexEntrypoint: not vault");

        // Get collateral token (OFT)
        Vault vault = Vault(_vault);
        IOFTV2 collateral = IOFTV2(vault.underlying());

        bytes memory adapterParams = abi.encodePacked(uint16(1), uint256(350000));

        // encode the payload
        bytes memory payload = abi.encode(_vault, _receiver, _collateralAmountIn, _minDUSDCAmountOut, _deadline, _short);

        // Estimate fee
        (uint256 nativeFee, uint256 zroFee) = collateral.estimateSendAndCallFee(
            _dstChainId, bytes32(bytes20(address(this))), _collateralAmountIn, payload, 0, false, adapterParams
        );

        // Send OFT and message to PerpDexGateway for opening position
        collateral.sendAndCall(
            msg.sender,
            _dstChainId,
            bytes32(bytes20(address(this))),
            _collateralAmountIn,
            payload,
            uint64(nativeFee),
            ICommonOFT.LzCallParams(payable(msg.sender), address(0x0), adapterParams)
        );
    }

    function _blockingLzReceive(uint16 _srcChainId, bytes memory _srcAddress, uint64 _nonce, bytes memory _payload)
        internal
        override
    {
        // Receive order result from PerpDexGateway
        (
            address vault,
            bool success,
            bool isShort,
            address receiver,
            uint256 excutedAmountOut,
            uint256 orginAmountIn,
            uint256 remainAmount,
            uint256 excutedPrice,
            uint256 excutedFee
        ) = abi.decode(_payload, (address, bool, bool, address, uint256, uint256, uint256, uint256, uint256));

        // Return result to Vault
        Vault(vault).receivePerpOrder(
            success, isShort, receiver, excutedAmountOut, orginAmountIn, remainAmount, excutedPrice, excutedFee
        );
    }
}
