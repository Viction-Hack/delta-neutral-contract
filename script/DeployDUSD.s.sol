// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {DUSD} from "../src/Doldrums/dusd/DUSD.sol";
import "./DeployFixture.s.sol";

// forge script script/DeployDUSD.s.sol:DeployDUSD --broadcast --legacy

contract DeployDUSD is DeployFixture {
    DUSD dusd;

    function setUp() public virtual override {
        super.setUp();
        dusd = deployDUSD();
    }

    function deployDUSD() public returns (DUSD) {
        DUSD _dusd = new DUSD(address(controller),vicLzEndpoint);

        (bool success, bytes memory result) =
            VRCIssuer.call{value: 10 ether}(abi.encodeWithSignature("apply(address)", _dusd));

        console.log("DUSD deployed : ", address(_dusd));
        return _dusd;
    }

    function run() public virtual {
        dusd.mint(user1, 20 * 10 ** 8);
        vm.stopBroadcast();

        vm.startBroadcast(vm.envUint("PRIVATE_KEY2"));
        dusd.transfer(user2, 1 * 10 ** 8); // gasless transaction
        dusd.transfer(user2, 1 * 10 ** 8); // gasless transaction
        dusd.approve(user2, 1 * 10 ** 8); // gasless transaction
        dusd.approve(user2, 2 * 10 ** 8); // gasless transaction
        dusd.burn(1 * 10 ** 8); // gasless transaction
        dusd.burn(1 * 10 ** 8); // gasless transaction
        vm.stopBroadcast();

        vm.startBroadcast(vm.envUint("PRIVATE_KEY3"));
        dusd.transferFrom(user1, user3, 1 * 10 ** 8); // gasless transaction
        // dusd.transferFrom(user1, user3, 1 * 10**8); // gasless transaction
        vm.stopBroadcast();
    }
}
