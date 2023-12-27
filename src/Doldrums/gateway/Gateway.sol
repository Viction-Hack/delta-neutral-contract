// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import {OApp, Origin, MessagingFee} from "@layerzerolabs/lz-evm-oapp-v2/contracts/oapp/OApp.sol";
import {Ownable} from "lib/openzeppelin-contracts/contracts/access/Ownable.sol";

abstract contract Gateway is OApp {
    constructor(address _endpoint, address _owner) OApp(_endpoint, _owner) Ownable(_owner) {}

    // Sends a message from the source to destination chain.
    function send(uint32 _dstEid, bytes memory _payload) public payable {
        bytes memory _options = "0x00030100110100000000000000000000000000030d40";
        _lzSend(
            _dstEid, // Destination chain's endpoint ID.
            _payload, // Encoded message payload being sent.
            _options, // Message execution options (e.g., gas to use on destination).
            MessagingFee(msg.value, 0), // Fee struct containing native gas and ZRO token.
            payable(msg.sender) // The refund address in case the send call reverts.
        );
    }

    /* @dev Quotes the gas needed to pay for the full omnichain transaction.
    * @return nativeFee Estimated gas fee in native gas.
    * @return lzTokenFee Estimated gas fee in ZRO token.
    */
    function quote(
        uint32 _dstEid, // Destination chain's endpoint ID.
        bytes memory _payload, // The message to send.
        bytes calldata _options, // Message execution options
        bool _payInLzToken // boolean for which token to return fee in
    ) public view returns (uint256 nativeFee, uint256 lzTokenFee) {
        MessagingFee memory fee = _quote(_dstEid, _payload, _options, _payInLzToken);
        return (fee.nativeFee, fee.lzTokenFee);
    }
}
