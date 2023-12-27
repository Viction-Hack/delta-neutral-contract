// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "./Fixture.t.sol";
import "../../src/Doldrums/perpdex/MockPerpDex.sol";
import {Vault} from "../../src/Doldrums/vault/Vault.sol";
import {Controller} from "../../src/Doldrums/core/Controller.sol";
import {MockDoldrumsGateway} from "./mock/MockDoldrumsGateway.sol";
import {MockPerpDexGateway} from "./mock/MockPerpDexGateway.sol";
import {MockRelayer} from "./mock/MockRelayer.sol";

contract UnitTest is Test, Fixture {
    MockPerpDex mockPerpDex;
    DUSD dusd;
    MOCKOFTV2 weth;
    MOCKOFTV2 dai;
    Vault vault;
    Vault vicVault;
    Vault wethVault;
    Vault daiVault;
    MockRelayer vicEndpoint;
    MockRelayer arbEndpoint;
    address receiver;
    uint32 constant vicId = 10196;
    uint32 constant arbId = 10231;

    function setUp() public override {
        super.setUp();
        vm.txGasPrice(25);
        mockPerpDex = new MockPerpDex();
        vicEndpoint = new MockRelayer();
        arbEndpoint = new MockRelayer();
        vault = new Vault(address(controller), address(mockPerpDex), address(0x0));
        dusd = new DUSD(address(controller), address(vicEndpoint));
        dai = new MOCKOFTV2("DAI","DAI",8, address(vicEndpoint));
        weth = new MOCKOFTV2("WETH","WETH",8, address(vicEndpoint));
        MockDoldrumsGateway mockDoldrumsGateway = new MockDoldrumsGateway(address(vicEndpoint));
        MockPerpDexGateway mockPerpDexGateway =
            new MockPerpDexGateway(address(arbEndpoint), address(mockDoldrumsGateway), address(mockPerpDex));
        mockDoldrumsGateway.setPerpDexGateway(address(mockPerpDexGateway));
        mockDoldrumsGateway.setPeer(arbId, bytes32(bytes20(address(mockPerpDexGateway))));
        mockPerpDexGateway.setPeer(vicId, bytes32(bytes20(address(mockDoldrumsGateway))));
        arbEndpoint.setEndpointId(address(mockPerpDexGateway), arbId);
        arbEndpoint.setCrossEndpoint(address(vicEndpoint));
        vicEndpoint.setEndpointId(address(mockDoldrumsGateway), vicId);
        vicEndpoint.setCrossEndpoint(address(arbEndpoint));
        vicVault = new Vault(address(controller),address(mockDoldrumsGateway),address(wvic));
        daiVault = new Vault(address(controller),address(mockDoldrumsGateway),address(dai));
        wethVault = new Vault(address(controller),address(mockDoldrumsGateway),address(weth));
        controller.setDUSD(address(dusd));
        controller.registerVault(address(wvic), address(vicVault));
        controller.registerVault(address(dai), address(daiVault));
        controller.registerVault(address(weth), address(wethVault));

        receiver = address(this);

        mockPerpDex.changeOraclePrice(address(vault), 3000); // 1000 USD로 설정
        mockPerpDex.changeOraclePrice(address(vicVault), 8 * 10 ** 7); // 0.8 USD로 설정
        mockPerpDex.changeOraclePrice(address(daiVault), 10 ** 8); // 1 USD로 설정
        mockPerpDex.changeOraclePrice(address(wethVault), 2000 * 10 ** 8); // 3 USD로 설정
    }

    function testMint() public returns (uint256) {
        vm.startPrank(user1);
        dai.mint(user1, 100 * 10 ** 8);
        // dai.mint(address(daiVault), 100 * 10 ** 8);
        dai.approve(address(controller), 100 * 10 ** 8);
        controller.mint(address(dai), user1, 100 * 10 ** 8, 50 * 10 ** 8, block.timestamp + 100);
        uint256 dusdBalance = dusd.balanceOf(user1);
        console.log("user1 dai balance : ", dai.balanceOf(user1));
        console.log("user1 dusd balance : ", dusdBalance);
        return dusdBalance;
        vm.stopPrank();
    }

    function testMintWithVic() public returns (uint256) {
        vm.startPrank(user1);
        vm.deal(user1, 100 * 10 ** 8);
        // vm.deal(address(vicVault), 100 * 10 ** 8);
        controller.mintWithVic{value: 100 * 10 ** 8}(user1, 0, block.timestamp + 100);
        uint256 dusdBalance = dusd.balanceOf(user1);
        console.log("user1 vic balance : ", user1.balance);
        console.log("user1 dusd balance : ", dusdBalance);
        return dusdBalance;
        vm.stopPrank();
    }

    function testRedeem() public {
        uint256 dusdBalance = testMint();
        vm.startPrank(user1);
        dusd.approve(address(controller), dusdBalance);
        controller.redeem(address(dai), user1, dusdBalance, 0, block.timestamp + 100);
        console.log("after user1 dusd balance : ", dusd.balanceOf(user1));
        console.log("after user1 dai balance : ", dai.balanceOf(user1));
        console.log("after controller dusd balance : ", dusd.balanceOf(address(controller)));
        vm.stopPrank();
    }

    function testRedeemWithVic() public {
        uint256 dusdBalance = testMintWithVic();
        vm.startPrank(user1);
        dusd.approve(address(controller), dusdBalance);
        controller.redeem(address(wvic), user1, dusdBalance, 0, block.timestamp + 100);
        console.log("after user1 dusd balance : ", dusd.balanceOf(user1));
        console.log("after user1 vic balance : ", user1.balance);
        console.log("after controller dusd balance : ", dusd.balanceOf(address(controller)));
        vm.stopPrank();
    }

    function testMintFail() public {
        vm.startPrank(user1);
        dai.mint(user1, 100 * 10 ** 8);
        // dai.mint(address(daiVault), 100 * 10 ** 8);
        dai.approve(address(controller), 100 * 10 ** 8);
        controller.mint(address(dai), user1, 100 * 10 ** 8, 100 * 10 ** 8, block.timestamp + 100);
        uint256 dusdBalance = dusd.balanceOf(user1);
        console.log("user1 dai balance : ", dai.balanceOf(user1));
        console.log("user1 dusd balance : ", dusdBalance);
        vm.stopPrank();
    }

    function testMintWithVicFail() public {
        vm.startPrank(user1);
        vm.deal(user1, 100 * 10 ** 8);
        // vm.deal(address(vicVault), 100 * 10 ** 8);
        controller.mintWithVic{value: 100 * 10 ** 8}(user1, 100 * 10 ** 8, block.timestamp + 100);
        uint256 dusdBalance = dusd.balanceOf(user1);
        console.log("user1 vic balance : ", user1.balance);
        console.log("user1 dusd balance : ", dusdBalance);
        vm.stopPrank();
    }

    function testRedeemFail() public {
        uint256 dusdBalance = testMint();
        vm.startPrank(user1);
        dusd.approve(address(controller), dusdBalance);
        controller.redeem(address(dai), user1, dusdBalance, 100 * 10 ** 8, block.timestamp + 100);
        console.log("after user1 dusd balance : ", dusd.balanceOf(user1));
        console.log("after user1 dai balance : ", dai.balanceOf(user1));
        console.log("after controller dusd balance : ", dusd.balanceOf(address(controller)));
        vm.stopPrank();
    }

    function testRedeemWithVicFail() public {
        uint256 dusdBalance = testMintWithVic();
        vm.startPrank(user1);
        dusd.approve(address(controller), dusdBalance);
        controller.redeem(address(wvic), user1, dusdBalance, 100 * 10 ** 8, block.timestamp + 100);
        console.log("after user1 dusd balance : ", dusd.balanceOf(user1));
        console.log("after user1 vic balance : ", user1.balance);
        console.log("after controller dusd balance : ", dusd.balanceOf(address(controller)));
        vm.stopPrank();
    }

    function testOpenPosition() public {
        uint256 amount = 10 ether;
        uint256 minAmountOut = 9 * 3000;
        uint256 deadline = block.timestamp + 1 hours;
        bool isShort = true;

        mockPerpDex.openPositionFor(isShort, address(vault), receiver, amount, minAmountOut, deadline);

        MockPerpDex.Position memory position = mockPerpDex.getPosition(receiver);

        if (isShort) {
            assertEq(position.amount, -int256(amount));
        } else {
            assertEq(position.amount, int256(amount));
        }
        assertGt(position.entryPrice, 0);
    }

    function testChangeOraclePrice() public {
        uint256 newPrice = 2000;
        mockPerpDex.changeOraclePrice(address(vault), newPrice);

        assertEq(mockPerpDex.priceOracle(address(vault)), newPrice);
    }
}
