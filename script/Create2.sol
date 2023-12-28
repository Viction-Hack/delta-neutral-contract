// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract Create2 {
    error Create2InsufficientBalance(uint256 received, uint256 minimumNeeded);

    error Create2EmptyBytecode();

    error Create2FailedDeployment();

    function deploy(uint256 amount, bytes32 salt, bytes memory bytecode) external payable returns (address addr) {
        if (msg.value < amount) {
            revert Create2InsufficientBalance(msg.value, amount);
        }

        if (bytecode.length == 0) {
            revert Create2EmptyBytecode();
        }

        assembly {
            addr := create2(amount, add(bytecode, 0x20), mload(bytecode), salt)
        }

        if (addr == address(0)) {
            revert Create2FailedDeployment();
        }
    }

    function createDSalted(bytes32 salt, bytes memory arg, bytes memory creationCode) public returns (address) {
        // This complicated expression just tells you how the address
        // can be pre-computed. It is just there for illustration.
        // You actually only need ``new D{salt: salt}(arg)``.
        // address predictedAddress = address(
        //     uint160(
        //         uint256(
        //             keccak256(
        //                 abi.encodePacked(
        //                     bytes1(0xff), address(this), salt, keccak256(abi.encodePacked(creationCode, arg))
        //                 )
        //             )
        //         )
        //     )
        // );
        address deployed;
        bytes memory bytecode = abi.encodePacked(creationCode, arg);
        assembly {
            deployed := create2(0, add(bytecode, 0x20), mload(bytecode), salt)
            if iszero(extcodesize(deployed)) { revert(0, 0) }
        }
        deployed.call(abi.encodeWithSignature("transferOwnership(address)", address(msg.sender)));

        return deployed;
    }

    function computeAddress(bytes32 salt, bytes32 bytecodeHash) external view returns (address addr) {
        address contractAddress = address(this);

        assembly {
            let ptr := mload(0x40)

            mstore(add(ptr, 0x40), bytecodeHash)
            mstore(add(ptr, 0x20), salt)
            mstore(ptr, contractAddress)
            let start := add(ptr, 0x0b)
            mstore8(start, 0xff)
            addr := keccak256(start, 85)
        }
    }
}
