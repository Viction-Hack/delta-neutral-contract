// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./Fixture.s.sol";

// forge script script/DeployDUSD.s.sol:DeployDUSD --broadcast --legacy

contract DeployFixture is Fixture {
    function setUp() public virtual override {
        super.setUp();

        console.log("#### On Main Chain ####");
        vm.selectFork(rpcIndex[main]);
        vm.startBroadcast(vm.envUint("PRIVATE_KEY1"));

        wvic = new MOCKNativeOFTV2("Wrapped Native VIC","WVIC",8,address(vicLzEndpoint));
        dai = new MOCKOFTV2("DAI","DAI",8, address(vicLzEndpoint));
        weth = new MOCKOFTV2("WETH","WETH",8, address(vicLzEndpoint));
        controller = new Controller(address(wvic));
        console.log("wvic = MOCKNativeOFTV2(payable(", address(wvic), "));");
        console.log("dai = MOCKOFTV2(", address(dai), ");");
        console.log("weth = MOCKOFTV2(", address(weth), ");");
        console.log("controller = Controller(", address(controller), ");");
    }
}
