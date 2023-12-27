// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./Fixture.s.sol";

// forge script script/DeployCross.s.sol --broadcast --gas-limit 10000000000 --with-gas-price 1000000000 --evm-version london --optimizer-runs 200
// forge script script/DeployCross.s.sol --broadcast --legacy

contract DeployCross is Fixture {
    function setUp() public virtual override {
        super.setUp();

        wvic = MOCKNativeOFTV2(payable(0x8269c57FBea0176ae1d4e302661c07ae11873751));
        dai = MOCKOFTV2(0xa21b20E49c92653bA143009B89d936818a3b7609);
        weth = MOCKOFTV2(0x43f9440E54123f288d319C355671Dad9F27c2986);
        controller = Controller(0x0789FdE58A90c4B80C273767dbe5165ba4c9c518);
        DUSD dusd = DUSD(0x8ec92FE248Fcf857d0F1cD1346AE3264bC0376A1);

        mockDoldrumsGateway = MockDoldrumsGateway(payable(0xCAD8BD4F0286B8dE164DC8548689F8C4788C901C));
        vicVault = Vault(0xde22aE28d9dad32938fe339f5E7a999Ff737e907);
        daiVault = Vault(0x95df672dA95De0b85272E46576d9C3EEd18c1482);
        wethVault = Vault(0xa5643aeDf7d69AABd53F2e3a610ACeC8B2ae6338);
        mockPerpDex = MockPerpDex(0x07DCBBd3dD79AD8adA931b184Ba3e5e61366588B);
        mockPerpDexGateway = MockPerpDexGateway(payable(0x1a46BE221D71E75b3c555E430B4bdAdE202B35D3));

        console.log("#### On Main Chain ####");
        vm.selectFork(rpcIndex[main]);
        vm.startBroadcast(vm.envUint("PRIVATE_KEY1"));
        // mockDoldrumsGateway.setPeer(arbId, bytes32(bytes20(address(mockPerpDexGateway))));
        mockDoldrumsGateway.setTrustedRemoteAddress(uint16(arbId), abi.encodePacked(address(mockPerpDexGateway)));
        // (bool success, bytes memory result) =
        //     VRCIssuer.call{value: 10 ether}(abi.encodeWithSignature("apply(address)", dusd));
        dai.mint(owner, 100 * 10 ** 8);
        weth.mint(owner, 100 * 10 ** 8);
        dai.approve(address(controller), 100 * 10 ** 8);
        address owner = vm.addr(vm.envUint("PRIVATE_KEY1"));
        address(mockDoldrumsGateway).call{value: 10 ether}("");
        controller.mint(address(dai), owner, 100 * 10 ** 8, 0, 1000000000000000000000000000);
        vm.stopBroadcast();
    }

    function run() public virtual {}
}
