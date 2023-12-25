// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script} from "forge-std/Script.sol";
import "forge-std/console.sol";
import {MockVRC25} from "../src/VRC25/mock/MockVRC25.sol";


// forge script script/DeployVRC25Script.s.sol:DeployVRC25Script --broadcast --legacy

contract DeployVRC25Script is Script {

    address owner;
    address user1;
    address user2;
    address user3;
    address user4;
    MockVRC25 mockVRC25;
    address constant VRCIssuer = 0x8c0faeb5C6bEd2129b8674F262Fd45c4e9468bee;

    function setUp() public {
        string memory victionTestRPC = "https://rpc-testnet.viction.xyz";
        vm.createFork(victionTestRPC);

        owner = vm.addr(vm.envUint("PRIVATE_KEY1"));
        user1 = vm.addr(vm.envUint("PRIVATE_KEY2"));
        user2 = vm.addr(vm.envUint("PRIVATE_KEY3"));
        user3 = makeAddr("user3");
        user4 = makeAddr("user4");

    }

    function deployMockVRC25() public returns (MockVRC25) {
        MockVRC25 _mockVRC25 = new MockVRC25("Test VRC25","TVRC",18);

        (bool success, bytes memory result) = VRCIssuer.call{value: 10 ether}(abi.encodeWithSignature("apply(address)", _mockVRC25));

        console.log("MockVRC25 deployed : ", address(_mockVRC25));
        return _mockVRC25;
    }

    function run() public {
        vm.selectFork(0);
        vm.startBroadcast(vm.envUint("PRIVATE_KEY1"));
        mockVRC25 = address(mockVRC25) == address(0) ? deployMockVRC25() : mockVRC25;
        mockVRC25.mint(user1, 20 * 10**18);
        vm.stopBroadcast();

        vm.startBroadcast(vm.envUint("PRIVATE_KEY2"));
        mockVRC25.transfer(user2, 1 * 10**18); // gasless transaction
        mockVRC25.transfer(user2, 1 * 10**18); // gasless transaction
        mockVRC25.approve(user2, 1 * 10**18); // gasless transaction
        mockVRC25.approve(user2, 2 * 10**18); // gasless transaction
        mockVRC25.burn(1 * 10**18); // gasless transaction
        mockVRC25.burn(1 * 10**18); // gasless transaction
        vm.stopBroadcast();

        vm.startBroadcast(vm.envUint("PRIVATE_KEY3"));
        mockVRC25.transferFrom(user1, user3, 1 * 10**18); // gasless transaction
        // mockVRC25.transferFrom(user1, user3, 1 * 10**18); // gasless transaction
        vm.stopBroadcast();
    }


}
