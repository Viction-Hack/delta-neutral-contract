// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./Fixture.s.sol";

// forge script script/DeployCross.s.sol --broadcast --gas-limit 10000000000 --with-gas-price 1000000000 --evm-version london --optimizer-runs 200
// forge script script/DeployCross.s.sol --broadcast --legacy

contract DeployCross is Fixture {
    function setUp() public virtual override {
        super.setUp();
        wvic = MOCKNativeOFTV2(payable(0x24c470BF5Fd6894BC935d7A4c0Aa65f6Ad8E3D5a));
        dai = MOCKOFTV2(0xEC3Ac809B27da7cdFC306792DA72aA896ed865eD);
        weth = MOCKOFTV2(0xA5f8B90975C6f3b15c90CbC75b44F10300b42bbe);
        controller = Controller(0x31C6d1884E408B63A910eF547afdA1180d919e13);
        dusd = DUSD(payable(0x46F96fB34Ac52DaE43E7FC441F429d2F5BcCDf52));

        dusd2 = DUSD(payable(0xf40E719D4F215712D9DC9a0568791E408c71760F));
        mockDoldrumsGateway = MockDoldrumsGateway(payable(0x6b5749854cF3d44688baa009bb419b82EFcD3a17));
        vicVault = Vault(0xD0d5E2931C9134b6E8DDe9Be67E814f4bFF50bC5);
        daiVault = Vault(0x109Eca9F83C18Da5563b5c978E421444c8A37E55);
        wethVault = Vault(0xAdbb76D0454De0365a9c1D6a93DdAD7CCa572BbA);
        mockPerpDex = MockPerpDex(0xf8efeBAec7C3a37106e14a8d4994Db730dDbC08F);
        mockPerpDexGateway = MockPerpDexGateway(payable(0xdb3975365f1c8258758D4D55687F659d58B74F13));
    }

    function run() public virtual {
        console.log("");
        console.log("#### On Main Chain ####");
        vm.selectFork(rpcIndex[main]);
        vm.startBroadcast(vm.envUint("PRIVATE_KEY1"));

        mockDoldrumsGateway.setTrustedRemoteAddress(uint16(arbId), abi.encodePacked(address(mockPerpDexGateway)));
        // mockDoldrumsGateway.setMinDstGas(arbId, 0, 220000);
        // mockDoldrumsGateway.setUseCustomAdapterParams(true);
        dusd.setTrustedRemoteAddress(uint16(arbId), abi.encodePacked(address(dusd2)));
        dusd.setMinDstGas(arbId, 0, 220000);
        dusd.setUseCustomAdapterParams(true);

        dai.mint(owner, 100 * 10 ** 8);
        weth.mint(owner, 100 * 10 ** 8);
        dai.approve(address(controller), 100 * 10 ** 8);
        address(mockDoldrumsGateway).call{value: 10 ether}("");
        controller.mint(address(dai), owner, 100 * 10 ** 8, 0, 1000000000000000000000000000);

        // (bool success, bytes memory result) =
        //     VRCIssuer.call{value: 10 ether}(abi.encodeWithSignature("apply(address)", dusd));
    }
}
