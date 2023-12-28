// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script} from "forge-std/Script.sol";
import "forge-std/console.sol";

import {Endpoint} from "../src/Layerzero/Endpoint.sol";
import {Controller} from "../src/Doldrums/core/Controller.sol";
import {MOCKNativeOFTV2} from "../src/mock/MockNativeOFTV2.sol";
import {MOCKOFTV2} from "../src/mock/MockOFTV2.sol";

import {DUSD} from "../src/Doldrums/dusd/DUSD.sol";

import {MockDoldrumsGateway} from "../test/Doldrums/mock/MockDoldrumsGateway.sol";
import {MockPerpDexGateway} from "../test/Doldrums/mock/MockPerpDexGateway.sol";
import {Vault} from "../src/Doldrums/vault/Vault.sol";
import {MockPerpDex} from "../src/Doldrums/perpdex/MockPerpDex.sol";

import {MockPerpDexGateway} from "../test/Doldrums/mock/MockPerpDexGateway.sol";
import {Vault} from "../src/Doldrums/vault/Vault.sol";
import {MockPerpDex} from "../src/Doldrums/perpdex/MockPerpDex.sol";

// forge script script/DeployDUSD.s.sol:DeployDUSD --broadcast --legacy

contract Fixture is Script {
    address owner;
    address user1;
    address user2;
    address user3;
    address user4;
    address constant VRCIssuer = 0x8c0faeb5C6bEd2129b8674F262Fd45c4e9468bee;
    Endpoint vicLzEndpoint;
    Endpoint arbLzEndpoint;
    uint16 constant vicId = 10196;
    uint16 constant arbId = 10106;
    string constant main = "viction";
    string constant sub = "arbitrum";
    mapping(string => uint256) rpcIndex;

    Controller controller;
    MOCKNativeOFTV2 wvic;
    MOCKOFTV2 weth;
    MOCKOFTV2 dai;

    DUSD dusd;
    DUSD dusd2;

    MockDoldrumsGateway mockDoldrumsGateway;
    MockPerpDexGateway mockPerpDexGateway;
    Vault vicVault;
    Vault wethVault;
    Vault daiVault;
    MockPerpDex mockPerpDex;

    function setUp() public virtual {
        // string memory victionTestRPC = "https://rpc-testnet.viction.xyz";
        string memory victionTestRPC = "https://rpc.testnet.tomochain.com";
        // string memory arbitrumTestRPC = "https://sepolia-rollup.arbitrum.io/rpc";
        string memory arbitrumTestRPC = "https://api.avax-test.network/ext/bc/C/rpc";

        rpcIndex["viction"] = vm.createFork(victionTestRPC);
        rpcIndex["arbitrum"] = vm.createFork(arbitrumTestRPC);

        vicLzEndpoint = Endpoint(0xae92d5aD7583AD66E49A0c67BAd18F6ba52dDDc1);
        arbLzEndpoint = Endpoint(0x93f54D755A063cE7bB9e6Ac47Eccc8e33411d706);

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
    }
}
