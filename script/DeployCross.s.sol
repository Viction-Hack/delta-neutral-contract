// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./Fixture.s.sol";

contract DeployCross is Fixture {
    function setUp() public virtual override {
        super.setUp();
        wvic = MOCKNativeOFTV2(payable(0x34c8A28C7d3549e4b2C31Ff21D3E72b310F12E83));
        dai = MOCKOFTV2(0x0967b1b87ec1cf2C61240063E4a7531EB835Df26);
        weth = MOCKOFTV2(0xB9C42b3962b8FBc506CE0AE973B79132dd626045);
        controller = Controller(0x1DFD5886eaF4427AEFD220f0412e2Bd6cF276e6C);
        dusd = DUSD(payable(0x22188081D69067620817Ef2F177E9661A3ca3878));

        dusd2 = DUSD(payable(0x6d4AbFA6522c63c3e1688E8953bB16A70e8e0E47));
        doldrumsGateway = DoldrumsGateway(payable(0xc2078ceDa8B259BE5364F15d47414b26D6a47867));
        vicVault = Vault(0x0c73d619Fc0503B4B35673E2fA90DC32Fb2bdDaF);
        daiVault = Vault(0xb84635caebAB1eB24F9D5e0Fc5998E70563A7bA5);
        wethVault = Vault(0x625d68469e7AC799dA325bcdA8651C01f2fBc35A);
        mockPerpDex = MockPerpDex(0xD12eF03c3F81011c99d82E11FbF1662751c25d65);
        perpDexGateway = PerpDexGateway(payable(0x1Ef5af8210aEc7d6aAFAFb0dd410AFD0A74b1aA2));
    }

    function run() public virtual {
        console.log("");
        console.log("#### On Main Chain ####");
        vm.selectFork(rpcIndex[main]);
        vm.startBroadcast(vm.envUint("PRIVATE_KEY1"));

        doldrumsGateway.setTrustedRemoteAddress(uint16(arbId), abi.encodePacked(address(perpDexGateway)));
        dusd.setTrustedRemoteAddress(uint16(arbId), abi.encodePacked(address(dusd2)));
        dusd.setMinDstGas(arbId, 0, 220000);
        dusd.setUseCustomAdapterParams(true);

        dai.mint(owner, 100 * 10 ** 8);
        weth.mint(owner, 100 * 10 ** 8);
        dai.approve(address(controller), 100 * 10 ** 8);
        controller.mint(address(dai), owner, 100 * 10 ** 8, 0, 1000000000000000000000000000);

        // (bool success, bytes memory result) =
        //     VRCIssuer.call{value: 10 ether}(abi.encodeWithSignature("apply(address)", dusd));
    }
}
