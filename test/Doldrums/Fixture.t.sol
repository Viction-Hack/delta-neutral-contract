// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "forge-std/Test.sol";
import "forge-std/console.sol";

import {Controller} from "../../src/Doldrums/core/Controller.sol";
import {DUSD} from "../../src/Doldrums/dusd/DUSD.sol";
import {Vault} from "../../src/Doldrums/vault/Vault.sol";
// import { MockERC20 } from "../../src/mock/MockERC20.sol";
import {MOCKOFTV2} from "../../src/mock/MockOFTV2.sol";
import {MOCKNativeOFTV2} from "../../src/mock/MockNativeOFTV2.sol";

contract Fixture is Test {
    address owner;
    address user1;
    address user2;
    address user3;
    address user4;
    address lzEndpoint;

    Controller controller;
    MOCKNativeOFTV2 wvic;

    function setUp() public virtual {
        owner = makeAddr("owner");
        user1 = makeAddr("user1");
        user2 = makeAddr("user2");
        user3 = makeAddr("user3");
        user4 = makeAddr("user4");

        wvic = new MOCKNativeOFTV2("Wrapped Native VIC","WVIC",8,lzEndpoint);
        controller = new Controller(address(wvic));
    }
}
