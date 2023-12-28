// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ILayerZeroEndpoint} from "@layerzerolabs/solidity-examples/contracts/lzApp/interfaces/ILayerZeroEndpoint.sol";
import {LzApp} from "@layerzerolabs/solidity-examples/contracts/lzApp/LzApp.sol";

contract MockRelayer is ILayerZeroEndpoint {
    uint16 public chainId;

    constructor(uint16 _chainId) {
        chainId = _chainId;
    }

    function send(
        uint16 _dstChainId,
        bytes calldata _destination,
        bytes calldata _payload,
        address payable _refundAddress,
        address _zroPaymentAddress,
        bytes calldata _adapterParams
    ) external payable override {
        LzApp(address(bytes20(_destination))).lzReceive(
            chainId, abi.encodePacked(bytes32(bytes20(msg.sender))), 0, _payload
        );
    }

    function receivePayload(
        uint16 _srcChainId,
        bytes calldata _srcAddress,
        address _dstAddress,
        uint64 _nonce,
        uint256 _gasLimit,
        bytes calldata _payload
    ) external override {
        // Mock implementation
    }

    function getInboundNonce(uint16 _srcChainId, bytes calldata _srcAddress) external view override returns (uint64) {
        return 0; // Returning a mock value
    }

    function getOutboundNonce(uint16 _dstChainId, address _srcAddress) external view override returns (uint64) {
        return 0; // Returning a mock value
    }

    function estimateFees(
        uint16 _dstChainId,
        address _userApplication,
        bytes calldata _payload,
        bool _payInZRO,
        bytes calldata _adapterParam
    ) external view override returns (uint256 nativeFee, uint256 zroFee) {
        return (0, 0); // Returning mock values
    }

    function getChainId() external view override returns (uint16) {
        return chainId;
    }

    function retryPayload(uint16 _srcChainId, bytes calldata _srcAddress, bytes calldata _payload) external override {
        // Mock implementation
    }

    function hasStoredPayload(uint16 _srcChainId, bytes calldata _srcAddress) external view override returns (bool) {
        return false; // Returning a mock value
    }

    function getSendLibraryAddress(address _userApplication) external view override returns (address) {
        return address(0); // Returning a mock address
    }

    function getReceiveLibraryAddress(address _userApplication) external view override returns (address) {
        return address(0); // Returning a mock address
    }

    function isSendingPayload() external view override returns (bool) {
        return false; // Returning a mock value
    }

    function isReceivingPayload() external view override returns (bool) {
        return false; // Returning a mock value
    }

    function getConfig(uint16 _version, uint16 _chainId, address _userApplication, uint256 _configType)
        external
        view
        override
        returns (bytes memory)
    {
        return ""; // Returning a mock value
    }

    function getSendVersion(address _userApplication) external view override returns (uint16) {
        return 0; // Returning a mock value
    }

    function getReceiveVersion(address _userApplication) external view override returns (uint16) {
        return 0; // Returning a mock value
    }

    function forceResumeReceive(uint16 _srcChainId, bytes calldata _srcAddress) external override {
        // Mock implementation
    }

    function setConfig(uint16 _version, uint16 _chainId, uint256 _configType, bytes calldata _config)
        external
        override
    {
        // Mock implementation
    }

    function setReceiveVersion(uint16 _version) external override {
        // Mock implementation
    }

    function setSendVersion(uint16 _version) external override {
        // Mock implementation
    }
}
