// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script} from "forge-std/Script.sol";
import "forge-std/console.sol";

import {Controller} from "../src/Doldrums/core/Controller.sol";
import {MOCKNativeOFTV2} from "../src/mock/MockNativeOFTV2.sol";
import {MOCKOFTV2} from "../src/mock/MockOFTV2.sol";

// forge script script/DeployDUSD.s.sol:DeployDUSD --broadcast --legacy

contract DeployFixture is Script {
    address owner;
    address user1;
    address user2;
    address user3;
    address user4;
    address constant VRCIssuer = 0x8c0faeb5C6bEd2129b8674F262Fd45c4e9468bee;
    address constant vicLzEndpoint = 0xae92d5aD7583AD66E49A0c67BAd18F6ba52dDDc1;
    address constant arbLzEndpoint = 0x6098e96a28E02f27B1e6BD381f870F1C8Bd169d3;
    uint32 constant vicId = 10196;
    uint32 constant arbId = 10231;
    string constant main = "viction";
    string constant sub = "arbitrum";
    mapping(string => uint256) rpcIndex;

    Controller controller;
    MOCKNativeOFTV2 wvic;
    MOCKOFTV2 weth;
    MOCKOFTV2 dai;

    function setUp() public virtual {
        string memory victionTestRPC = "https://rpc-testnet.viction.xyz";
        string memory arbitrumTestRPC = "https://sepolia-rollup.arbitrum.io/rpc";

        rpcIndex["viction"] = vm.createFork(victionTestRPC);
        rpcIndex["arbitrum"] = vm.createFork(arbitrumTestRPC);

        owner = vm.addr(vm.envUint("PRIVATE_KEY1"));
        user1 = vm.addr(vm.envUint("PRIVATE_KEY2"));
        user2 = vm.addr(vm.envUint("PRIVATE_KEY3"));
        user3 = makeAddr("user3");
        user4 = makeAddr("user4");

        console.log("owner: ", owner);
        console.log("user1: ", user1);
        console.log("user2: ", user2);
        console.log("user3: ", user3);
        console.log("user4: ", user4);

        console.log("#### On Main Chain ####");
        vm.selectFork(rpcIndex[main]);
        vm.startBroadcast(vm.envUint("PRIVATE_KEY1"));
        wvic = new MOCKNativeOFTV2("Wrapped Native VIC","WVIC",8,vicLzEndpoint);
        dai = new MOCKOFTV2("DAI","DAI",8, address(vicLzEndpoint));
        weth = new MOCKOFTV2("WETH","WETH",8, address(vicLzEndpoint));
        controller = new Controller(address(wvic));
        console.log("WVIC deployed : ", address(wvic));
        console.log("DAI deployed : ", address(dai));
        console.log("WETH deployed : ", address(weth));
        console.log("Controller deployed : ", address(controller));
    }
}
