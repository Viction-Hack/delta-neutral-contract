// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Vault} from "../vault/Vault.sol";
import {IOFTV2} from "@layerzerolabs/solidity-examples/contracts/token/oft/v2/interfaces/IOFTV2.sol";
import {Ownable} from "openzeppelin-contracts/contracts/access/Ownable.sol";

contract PerpDexEntrypoint {
    uint16 private constant _dstChainId = 0x0001;

    function openPositionFor(
        address _vault,
        address _receiver,
        uint256 _collateralAmountIn,
        uint256 _minDUSDCAmountOut,
        uint256 _deadline,
        bool _short
    ) external onlyOwner {
        Vault vault = Vault(_vault);
        IOFTV2 collateral = IOFTV2(vault.underlying());

        // encode the adapter parameters
        uint16 version = 1;
        uint256 gasForDestinationLzReceive = 350000;
        bytes memory adapterParams = abi.encodePacked(version, gasForDestinationLzReceive);

        // encode the payload
        bytes memory payload = abi.encode(_vault, _receiver, _collateralAmountIn, _minDUSDCAmountOut, _deadline, _short);

        (uint256 nativeFee, uint256 zroFee) = collateral.estimateSendAndCallFee(
            _dstChainId, bytes32(bytes20(address(this))), _collateralAmountIn, false, adapterParams
        );

        // send the transaction
        collateral.sendAndCall(
            collateral.owner(),
            _dstChainId,
            bytes32(bytes20(address(this))),
            _collateralAmountIn,
            payload,
            nativeFee,
            IOFTV2.LzCallParams(address(0x0), address(0x0), adapterParams)
        );
    }

    function _blockingLzReceive(uint16 _srcChainId, bytes memory _srcAddress, uint64 _nonce, bytes memory _payload)
        internal
        override
    {}
}
