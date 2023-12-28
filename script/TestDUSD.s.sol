// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./Fixture.s.sol";
// import {DUSD} from "../test/Doldrums/mock/DUSD.sol";
import {DUSD} from "../src/Doldrums/dusd/DUSD.sol";

// forge script script/DeployCross.s.sol --broadcast --gas-limit 10000000000 --with-gas-price 1000000000 --evm-version london --optimizer-runs 200
// forge script script/DeployCross.s.sol --broadcast --legacy

contract TestDUSD is Fixture {
    DUSD Tdusd;
    DUSD Tdusd2;

    function setUp() public virtual override {
        super.setUp();
        console.log("#### On Main Chain ####");
        vm.selectFork(rpcIndex[main]);
        vm.startBroadcast(vm.envUint("PRIVATE_KEY1"));

        Tdusd = new DUSD(owner,address(0),address(vicLzEndpoint));
        vm.stopBroadcast();

        console.log("#### On Sub Chain ####");
        vm.selectFork(rpcIndex[sub]);
        vm.startBroadcast(vm.envUint("PRIVATE_KEY1"));

        Tdusd2 = new DUSD(owner,address(0),address(arbLzEndpoint));
        Tdusd2.setTrustedRemoteAddress(vicId, abi.encodePacked(address(Tdusd)));
        Tdusd2.setMinDstGas(vicId, 0, 220000);
        Tdusd2.setUseCustomAdapterParams(true);
        vm.stopBroadcast();

        console.log("#### On Main Chain ####");
        vm.selectFork(rpcIndex[main]);
        vm.startBroadcast(vm.envUint("PRIVATE_KEY1"));

        Tdusd.setTrustedRemoteAddress(arbId, abi.encodePacked(address(Tdusd2)));
        Tdusd.setMinDstGas(arbId, 0, 220000);
        Tdusd.setUseCustomAdapterParams(true);
        Tdusd.mintTokens(owner, 10000);
    }

    function run() public virtual {
        // bytes memory _adapterParams = abi.encodePacked(uint16(1), uint256(225000));
        // Tdusd.setUseCustomAdapterParams(true);

        // Tdusd.setMinDstGas(arbId, 0, 100000);

        // (uint256 nativeFee, uint256 zroFee) =
        //     Tdusd.estimateSendFee(arbId, abi.encodePacked(owner), 5000, false, _adapterParams);

        Tdusd.sendFrom{value: 10 ether}(owner, arbId, abi.encodePacked(bytes20(address(user1))), 5000);
    }
}
