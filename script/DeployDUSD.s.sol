// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./DeployFixture.s.sol";
import {Create2} from "./Create2.sol";

contract DeployDUSD is DeployFixture {
    function setUp() public virtual override {
        super.setUp();
        dusd = deployDUSD(address(controller), address(vicLzEndpoint));
        address(dusd).call{value: 10 ether}("");
        console.log("dusd = DUSD(payable(", address(dusd), "));");
    }

    function deployDUSD(address _controller, address _endPoint) public returns (DUSD) {
        DUSD _dusd = new DUSD(owner, _controller, _endPoint);

        // bytes32 salt = "12349";
        // bytes memory creationCode = abi.encodePacked(type(DUSD).creationCode);

        // address computedAddress = create2.computeAddress(salt, keccak256(creationCode));
        // address deployedAddress = create2.deploy(0, salt, creationCode);
        // address deployedAddress = create2.createDSalted(salt, abi.encode(_controller, _endPoint), creationCode);
        // DUSD _dusd = DUSD(deployedAddress);

        // DUSD _dusd = new DUSD{salt: salt}(owner,_controller, _endPoint);
        // require(address(_dusd) == predictedAddress);

        // console.log("dusd = DUSD(", address(_dusd), ");");
        return _dusd;
    }

    function run() public virtual {
        // (bool success, bytes memory result) =
        //     VRCIssuer.call{value: 10 ether}(abi.encodeWithSignature("apply(address)", dusd));
        // dusd.mint(user1, 20 * 10 ** 8);
        // vm.stopBroadcast();

        // vm.startBroadcast(vm.envUint("PRIVATE_KEY2"));
        // dusd.transfer(user2, 1 * 10 ** 8); // gasless transaction
        // dusd.transfer(user2, 1 * 10 ** 8); // gasless transaction
        // dusd.approve(user2, 1 * 10 ** 8); // gasless transaction
        // dusd.approve(user2, 2 * 10 ** 8); // gasless transaction
        // dusd.burn(1 * 10 ** 8); // gasless transaction
        // dusd.burn(1 * 10 ** 8); // gasless transaction
        // vm.stopBroadcast();

        // vm.startBroadcast(vm.envUint("PRIVATE_KEY3"));
        // dusd.transferFrom(user1, user3, 1 * 10 ** 8); // gasless transaction
        // // dusd.transferFrom(user1, user3, 1 * 10**8); // gasless transaction
        // vm.stopBroadcast();
    }
}
