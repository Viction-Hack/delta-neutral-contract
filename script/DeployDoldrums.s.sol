// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script} from "forge-std/Script.sol";
import "forge-std/console.sol";

import {DUSD} from "../src/Doldrums/dusd/DUSD.sol";


// forge script script/DeployDUSD.s.sol:DeployDUSD --broadcast --legacy

contract DeployDoldrums is Script {

    address owner;
    address user1;
    address user2;
    address user3;
    address user4;
    DUSD dusd;
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

    function deployDUSD() public returns (DUSD) {
        
        DUSD _dusd = new DUSD(makeAddr("controller"),makeAddr("lzEndpoint"));

        (bool success, bytes memory result) = VRCIssuer.call{value: 10 ether}(abi.encodeWithSignature("apply(address)", _dusd));

        console.log("DUSD deployed : ", address(_dusd));
        return _dusd;
    }

    function run() public {
        vm.selectFork(0);
        vm.startBroadcast(vm.envUint("PRIVATE_KEY1"));
        dusd = address(dusd) == address(0) ? deployDUSD() : dusd;
        dusd.mint(user1, 20 * 10**8);
        vm.stopBroadcast();

        vm.startBroadcast(vm.envUint("PRIVATE_KEY2"));
        dusd.transfer(user2, 1 * 10**8); // gasless transaction
        dusd.transfer(user2, 1 * 10**8); // gasless transaction
        dusd.approve(user2, 1 * 10**8); // gasless transaction
        dusd.approve(user2, 2 * 10**8); // gasless transaction
        dusd.burn(1 * 10**8); // gasless transaction
        dusd.burn(1 * 10**8); // gasless transaction
        vm.stopBroadcast();

        vm.startBroadcast(vm.envUint("PRIVATE_KEY3"));
        dusd.transferFrom(user1, user3, 1 * 10**8); // gasless transaction
        // dusd.transferFrom(user1, user3, 1 * 10**8); // gasless transaction
        vm.stopBroadcast();
    }


}
