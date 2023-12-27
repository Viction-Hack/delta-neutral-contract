// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./DeployDUSD.s.sol";

// forge script script/DeployDoldrums.s.sol --broadcast --legacy

contract DeployDoldrums is DeployDUSD {
    function setUp() public virtual override {
        super.setUp();
        mockDoldrumsGateway = new MockDoldrumsGateway(arbId,address(vicLzEndpoint));
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
        mockPerpDexGateway = new MockPerpDexGateway(vicId,address(arbLzEndpoint), address(mockPerpDex));
        address(mockPerpDexGateway).call{value: 0.2 ether}("");
        // mockPerpDexGateway.setPeer(vicId, bytes32(bytes20(address(mockDoldrumsGateway))));
        mockPerpDexGateway.setTrustedRemoteAddress(uint16(vicId), abi.encodePacked(address(mockDoldrumsGateway)));
        vm.stopBroadcast();

        console.log("mockDoldrumsGateway = MockDoldrumsGateway(payable(", address(mockDoldrumsGateway), "));");
        console.log("vicVault = Vault(", address(vicVault), ");");
        console.log("daiVault = Vault(", address(daiVault), ");");
        console.log("wethVault = Vault(", address(wethVault), ");");
        console.log("mockPerpDex = MockPerpDex(", address(mockPerpDex), ");");
        console.log("mockPerpDexGateway = MockPerpDexGateway(payable(", address(mockPerpDexGateway), "));");
    }

    function run() public virtual override {
        super.run();
    }
}
