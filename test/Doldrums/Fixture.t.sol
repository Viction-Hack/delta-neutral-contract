// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "forge-std/Test.sol";
import "forge-std/console.sol";

import { Controller } from "../../src/Doldrums/core/Controller.sol";
import { DUSD } from "../../src/Doldrums/dusd/DUSD.sol";
import { Vault } from "../../src/Doldrums/vault/Vault.sol";
import { MockERC20 } from "../../src/mock/MockERC20.sol";

contract Fixture is Test {

    address owner;
    address user1;
    address user2;
    address user3;
    address user4;

    Controller controller;
    DUSD dusd;
    MockERC20 mockERC20;
    Vault VicVault;
    Vault Erc20Vault;

    function setUp() public {
        owner = makeAddr("owner");
        user1 = makeAddr("user1");
        user2 = makeAddr("user2");
        user3 = makeAddr("user3");
        user4 = makeAddr("user4");

        controller = new Controller();
        dusd = new DUSD(address(controller),makeAddr("lzEndpoint"));
        address perpDex = makeAddr("PerpDex");
        VicVault = new Vault(address(controller),perpDex,address(0));
        mockERC20 = new MockERC20("Test ERC20","TERC20",18);
        Erc20Vault = new Vault(address(controller),perpDex,address(mockERC20));
        controller.setDUSD(address(dusd));
        controller.registerVault(address(0), address(VicVault));
        controller.registerVault(address(mockERC20), address(Erc20Vault));
    }

    function testMintWithVic() public {
        vm.startPrank(user1);
        vm.deal(user1, 100 ether);
        controller.mint(user1, 100 ether);
        console.log("user1 dusd balance : ", dusd.balanceOf(user1));
        vm.stopPrank();
    }

    function testMintWithERC20() public {
        vm.startPrank(user1);
        mockERC20.mint(user1, 100 ether);
        mockERC20.approve(address(controller), 100 ether);
        controller.mint(user1, 100 ether);
        console.log("user1 dusd balance : ", dusd.balanceOf(user1));
        vm.stopPrank();
    }

}