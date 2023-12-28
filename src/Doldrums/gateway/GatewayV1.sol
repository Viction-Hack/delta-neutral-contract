pragma solidity ^0.8.0;
pragma abicoder v2;

import {NonblockingLzApp} from "@layerzerolabs/solidity-examples/contracts/lzApp/NonblockingLzApp.sol";
import {Ownable} from "lib/openzeppelin-contracts/contracts/access/Ownable.sol";

abstract contract Gateway is NonblockingLzApp {
    constructor(address _endpoint, address _owner) NonblockingLzApp(_endpoint) Ownable(_owner) {}

    receive() external payable {}

    function withdraw() public onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    // Sends a message from the source to destination chain.
    function send(uint16 _dstEid, bytes memory _payload) public payable {
        // encode the adapter parameters
        uint16 version = 1;
        uint256 gasForDestinationLzReceive = 350000;
        bytes memory adapterParams = abi.encodePacked(version, gasForDestinationLzReceive);

        (uint256 nativeFee, uint256 zroFee) =
            lzEndpoint.estimateFees(_dstEid, address(this), _payload, false, adapterParams);

        // send LayerZero message
        _lzSend( // {value: messageFee} will be paid out of this contract!
            _dstEid, // destination chainId
            _payload, // abi.encode()'ed bytes
            payable(this), // (msg.sender will be this contract) refund address (LayerZero will refund any extra gas back to caller of send())
            address(0x0), // future param, unused for this example
            adapterParams, // v1 adapterParams, specify custom destination gas qty
            nativeFee
        );
    }

    function _nonblockingLzReceive(
        uint16 _srcChainId,
        bytes memory, /*_srcAddress*/
        uint64, /*_nonce*/
        bytes memory _payload
    ) internal override {
        receiveMessage(_payload);
    }

    // function lzReceive(uint16 _srcChainId, bytes calldata _srcAddress, uint64 _nonce, bytes calldata _payload)
    //     public
    //     virtual
    //     override
    // {
    //     bytes memory trustedRemote = trustedRemoteLookup[_srcChainId];
    //     // if will still block the message pathway from (srcChainId, srcAddress). should not receive message from untrusted remote.
    //     require(
    //         _srcAddress.length == trustedRemote.length && trustedRemote.length > 0
    //             && keccak256(_srcAddress) == keccak256(trustedRemote),
    //         "LzApp: invalid source sending contract"
    //     );

    //     _blockingLzReceive(_srcChainId, _srcAddress, _nonce, _payload);
    // }

    function receiveMessage(bytes memory message) public virtual;
}
