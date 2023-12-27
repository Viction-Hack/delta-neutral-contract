// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./DeployDUSD.s.sol";

import {MockDoldrumsGateway} from "../test/Doldrums/mock/MockDoldrumsGateway.sol";
import {MockPerpDexGateway} from "../test/Doldrums/mock/MockPerpDexGateway.sol";
import {Vault} from "../src/Doldrums/vault/Vault.sol";
import {MockPerpDex} from "../src/Doldrums/perpdex/MockPerpDex.sol";

// forge script script/DeployDUSD.s.sol:DeployDUSD --broadcast --legacy

contract DeployDoldrums is DeployDUSD {
    MockDoldrumsGateway mockDoldrumsGateway;
    MockPerpDexGateway mockPerpDexGateway;
    Vault vicVault;
    Vault wethVault;
    Vault daiVault;
    MockPerpDex mockPerpDex;

    function setUp() public virtual override {
        super.setUp();

        mockDoldrumsGateway = new MockDoldrumsGateway(vicLzEndpoint);
        address(mockDoldrumsGateway).call{value: 0.1 ether}("");
        vicVault = new Vault(address(controller),address(mockDoldrumsGateway),address(wvic));
        daiVault = new Vault(address(controller),address(mockDoldrumsGateway),address(dai));
        wethVault = new Vault(address(controller),address(mockDoldrumsGateway),address(weth));
        controller.setDUSD(address(dusd));
        controller.registerVault(address(wvic), address(vicVault));
        controller.registerVault(address(dai), address(daiVault));
        controller.registerVault(address(weth), address(wethVault));
        vm.stopBroadcast();

        console.log("");
        console.log("#### On Sub Chain ####");
        vm.selectFork(rpcIndex[sub]);
        vm.startBroadcast(vm.envUint("PRIVATE_KEY1"));

        mockPerpDex = new MockPerpDex();
        mockPerpDex.changeOraclePrice(address(vicVault), 8 * 10 ** 7); // 0.8 USD로 설정
        mockPerpDex.changeOraclePrice(address(daiVault), 10 ** 8); // 1 USD로 설정
        mockPerpDex.changeOraclePrice(address(wethVault), 2000 * 10 ** 8); // 3 USD로 설정
        mockPerpDexGateway = new MockPerpDexGateway(address(arbLzEndpoint), address(mockPerpDex));
        address(mockPerpDexGateway).call{value: 0.1 ether}("");
        mockPerpDexGateway.setPeer(vicId, bytes32(bytes20(address(mockDoldrumsGateway))));
        vm.stopBroadcast();

        console.log("#### On Main Chain ####");
        vm.selectFork(rpcIndex[main]);
        vm.startBroadcast(vm.envUint("PRIVATE_KEY1"));
        mockDoldrumsGateway.setPeer(arbId, bytes32(bytes20(address(mockPerpDexGateway))));
        vm.stopBroadcast();
    }
}
