// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {MessagingParams} from "@layerzerolabs/lz-evm-protocol-v2/contracts/interfaces/ILayerZeroEndpointV2.sol";

interface IGateway {
    function lzReceive(
        bytes calldata payload // encoded message payload being received
    ) external;
}

contract MockRelayer {
    address public gateway;
    address public crossEndpoints;

    function setGateway(address _gateway) external {
        gateway = _gateway;
    }

    function setCrossEndpoint(address _crossEndpoint) external {
        crossEndpoints = _crossEndpoint;
    }

    function send(
        uint16 _dstChainId,
        bytes calldata _destination,
        bytes calldata _payload,
        address payable _refundAddress,
        address _zroPaymentAddress,
        bytes calldata _adapterParams
    ) external payable {
        MockRelayer(crossEndpoints).cross(_payload);
    }

    function cross(bytes calldata _payload) external payable {
        IGateway(gateway).lzReceive(_payload);
    }
}
