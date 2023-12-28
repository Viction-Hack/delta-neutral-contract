// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./DeployCross.s.sol";

// forge script script/DeployCross.s.sol --broadcast --gas-limit 10000000000 --with-gas-price 1000000000 --evm-version london --optimizer-runs 200
// forge script script/DeployCross.s.sol --broadcast --legacy

contract ChekcDUSD is DeployCross {
    function setUp() public virtual override {
        super.setUp();
    }

    function run() public virtual override {
        vm.selectFork(rpcIndex[main]);
        // vm.startBroadcast(vm.envUint("PRIVATE_KEY1"));
        // (bool success, bytes memory result) =
        //     VRCIssuer.call{value: 10 ether}(abi.encodeWithSignature("apply(address)", dusd));

        // dusd.transfer(address(user1), 5 * 10 ** 8);
        // vm.stopBroadcast();

        // console.log("");
        // console.log("#### change user to check gasless ####");
        // vm.startBroadcast(vm.envUint("PRIVATE_KEY2"));
        // dusd.transfer(address(user2), 4 * 10 ** 8); // gasless transaction
        // console.log("user2 balance: ", dusd.balanceOf(address(user2)));
        // vm.stopBroadcast();

        // vm.startBroadcast(vm.envUint("PRIVATE_KEY1"));
        // // address(dusd).call{value: 10 ether}("");
        // dusd.sendFrom(owner, arbId, abi.encodePacked(bytes20(address(owner))), 10000);
        // vm.stopBroadcast();

        console.log("#### On Sub Chain ####");
        vm.selectFork(rpcIndex[sub]);
        vm.startBroadcast(vm.envUint("PRIVATE_KEY1"));
        // address(dusd2).call{value: 0.1 ether}("");
        dusd2.sendFrom(owner, vicId, abi.encodePacked(bytes20(address(owner))), 5000);
    }
}
