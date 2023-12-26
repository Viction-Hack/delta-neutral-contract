// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "forge-std/Test.sol";
import "forge-std/console.sol";

import { Controller } from "../../src/Doldrums/core/Controller.sol";
import { DUSD } from "../../src/Doldrums/dusd/DUSD.sol";
import { Vault } from "../../src/Doldrums/vault/Vault.sol";
// import { MockERC20 } from "../../src/mock/MockERC20.sol";
import { MOCKOFTV2 } from "../../src/mock/MockOFTV2.sol";
import { MOCKNativeOFTV2 } from "../../src/mock/MockNativeOFTV2.sol";

contract Fixture is Test {

    address constant lzEndpoint = 0xae92d5aD7583AD66E49A0c67BAd18F6ba52dDDc1;

    address owner;
    address user1;
    address user2;
    address user3;
    address user4;

    Controller controller;
    DUSD dusd;
    MOCKOFTV2 mockOFTV2;
    MOCKNativeOFTV2 mockNativeOFTV2;
    Vault VicVault;
    Vault Erc20Vault;

    function setUp() public {
        owner = makeAddr("owner");
        user1 = makeAddr("user1");
        user2 = makeAddr("user2");
        user3 = makeAddr("user3");
        user4 = makeAddr("user4");

        mockOFTV2 = new MOCKOFTV2("Test ERC20","TERC20",8,lzEndpoint);
        mockNativeOFTV2 = new MOCKNativeOFTV2("Test Native VIC","TVIC",8,lzEndpoint);

        controller = new Controller(address(mockNativeOFTV2));
        dusd = new DUSD(address(controller),lzEndpoint);
        address perpDex = makeAddr("PerpDex");
        VicVault = new Vault(address(controller),perpDex,address(0));

        Erc20Vault = new Vault(address(controller),perpDex,address(mockOFTV2));
        controller.setDUSD(address(dusd));
        controller.registerVault(address(mockNativeOFTV2), address(VicVault));
        controller.registerVault(address(mockOFTV2), address(Erc20Vault));
    }

    function testMintWithVic() public {
        vm.startPrank(user1);
        vm.deal(user1, 100 ether);
        controller.mintWithVic{value : 100 ether}(user1, 100, block.timestamp + 100);
        console.log("user1 dusd balance : ", dusd.balanceOf(user1));
        vm.stopPrank();
    }

    function testMintWithERC20() public {
        vm.startPrank(user1);
        mockOFTV2.mint(user1, 100 * 10 ** 8);
        mockOFTV2.approve(address(controller), 100 * 10 ** 8);
        controller.mint(address(mockOFTV2), user1, 100 * 10 ** 8, 100, block.timestamp + 100); 
        console.log("user1 dusd balance : ", dusd.balanceOf(user1));
        vm.stopPrank();
    }

}