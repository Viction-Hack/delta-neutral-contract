// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {MessagingParams} from "@layerzerolabs/lz-evm-protocol-v2/contracts/interfaces/ILayerZeroEndpointV2.sol";
import {
    ILayerZeroReceiver, Origin
} from "@layerzerolabs/lz-evm-protocol-v2/contracts/interfaces/ILayerZeroReceiver.sol";

contract MockRelayer {
    mapping(address => uint32) public endpointIds;
    address public crossEndpoints;
    mapping(address => uint32) public nonce;

    function setDelegate(address _delegate) external {}

    function setEndpointId(address _endpoint, uint32 _eid) external {
        endpointIds[_endpoint] = _eid;
    }

    function setCrossEndpoint(address _crossEndpoint) external {
        crossEndpoints = _crossEndpoint;
    }

    function send(MessagingParams calldata _params, address _refundAddress) external payable {
        Origin memory _origin = Origin(endpointIds[msg.sender], bytes32(bytes20(msg.sender)), nonce[msg.sender]);
        MockRelayer(crossEndpoints).cross(_origin, _params, _refundAddress);
    }

    function cross(Origin memory _origin, MessagingParams calldata _params, address _refundAddress) external payable {
        address _receiver = address(bytes20(_params.receiver));
        ILayerZeroReceiver(_receiver).lzReceive(_origin, bytes32(0), _params.message, address(0), bytes(""));
    }
}
