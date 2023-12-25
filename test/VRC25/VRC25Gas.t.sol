// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "forge-std/Test.sol";
import "forge-std/console.sol";

import { MockVRC25 } from "../../src/VRC25/mock/MockVRC25.sol";

contract VRC25GasTest is Test {

    address owner;
    address user1;
    address user2;
    address user3;
    address user4;
    MockVRC25 mockVRC25;

    function setUp() public {
        owner = makeAddr("owner");
        user1 = makeAddr("user1");
        user2 = makeAddr("user2");
        user3 = makeAddr("user3");
        user4 = makeAddr("user4");
        vm.deal(owner, 100 ether);
        vm.startPrank(owner);
        mockVRC25 = new MockVRC25("Test VRC25","TVRC",0);
        vm.stopPrank();
    }

    function testDefault() public {
        vm.startPrank(owner);
        mockVRC25.mint(user1, 100);
        mockVRC25.mint(owner, 100);
        mockVRC25.mint(user4, 100);
        vm.stopPrank();

        // vm.startPrank(user1);
        // vm.roll(block.number + 1);
        // mockVRC25._transfer(user1,user2, 5); // 25594 gas
        // mockVRC25._transfer(user1,user2, 10); // 3694 gas
        // vm.roll(block.number + 1);
        // mockVRC25._transfer(user1,user3, 85); // 20476 gas != 25594 - (3694 - 2956)
        // vm.roll(block.number + 1);
        // mockVRC25._transfer(owner,user1, 10); // 23594 gas != 25594
        // mockVRC25._transfer(owner,user1, 90); // 2956 gas
        // vm.roll(block.number + 1);
        // mockVRC25._transfer(user4,owner, 100); // 18876 gas != 23594 - (3694 - 2956)

        // vm.stopPrank();
    }


}