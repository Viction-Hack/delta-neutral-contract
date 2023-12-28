// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "./Fixture.t.sol";
import "../../src/Doldrums/perpdex/MockPerpDex.sol";
import {Vault} from "../../src/Doldrums/vault/Vault.sol";
import {Controller} from "../../src/Doldrums/core/Controller.sol";
import {DoldrumGateway} from "../../src/Doldrums/gateway/DoldrumGateway.sol";
import {PerpDexGateway} from "../../src/Doldrums/gateway/PerpDexGateway.sol";
import {MockRelayer} from "./mock/MockRelayer.sol";

contract LzTest is Test, Fixture {
    MockPerpDex mockPerpDex;
    MockRelayer mockRelayer;
    DUSD dusd;
    MOCKOFTV2 weth;
    MOCKOFTV2 dai;
    Vault vault;
    Vault vicVault;
    Vault wethVault;
    Vault daiVault;
    address receiver;

    function setUp() public override {
        super.setUp();
        vm.txGasPrice(25);

        uint16 victionChainId = 0x0001;
        uint16 arbitrumChainId = 0x0002;

        mockPerpDex = new MockPerpDex();
        mockRelayer = new MockRelayer(victionChainId);
        lzEndpoint = address(mockRelayer);
        vault = new Vault(address(controller), address(mockPerpDex), address(0x0));
        dusd = new DUSD(address(controller), lzEndpoint);
        dai = new MOCKOFTV2("DAI", "DAI", 8, lzEndpoint);
        weth = new MOCKOFTV2("WETH", "WETH", 8, lzEndpoint);
        DoldrumGateway doldrumGateway = new DoldrumGateway(address(lzEndpoint));

        PerpDexGateway perpDexGateway =
            new PerpDexGateway(address(doldrumGateway), address(mockPerpDex), address(lzEndpoint));

        doldrumGateway.setPerpDexGateway(address(perpDexGateway));

        doldrumGateway.setTrustedRemoteAddress(arbitrumChainId, abi.encodePacked(address(perpDexGateway)));

        doldrumGateway.setMinDstGas(uint16(0x0001), uint16(0x0000), uint256(300000));
        perpDexGateway.setMinDstGas(uint16(0x0001), uint16(0x0000), uint256(300000));

        dai.setMinDstGas(uint16(0x0002), uint16(0x0000), uint256(300000));
        dai.setMinDstGas(uint16(0x0002), uint16(0x0001), uint256(300000));
        // dai.setTrustedRemoteAddress(victionChainId, abi.encodePacked(address(controller)));
        dai.setTrustedRemoteAddress(arbitrumChainId, abi.encodePacked(address(perpDexGateway)));

        dusd.setMinDstGas(uint16(0x0002), uint16(0x0000), uint256(300000));
        dusd.setMinDstGas(uint16(0x0002), uint16(0x0001), uint256(300000));
        dusd.setTrustedRemoteAddress(arbitrumChainId, abi.encodePacked(address(perpDexGateway)));

        weth.setMinDstGas(uint16(0x0002), uint16(0x0000), uint256(300000));
        weth.setMinDstGas(uint16(0x0002), uint16(0x0001), uint256(300000));
        weth.setTrustedRemoteAddress(arbitrumChainId, abi.encodePacked(address(perpDexGateway)));

        vicVault = new Vault(address(controller), address(doldrumGateway), address(wvic));
        daiVault = new Vault(address(controller), address(doldrumGateway), address(dai));
        wethVault = new Vault(address(controller), address(doldrumGateway), address(weth));
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

        // if (isShort) {
        //     assertEq(position.amount, -int256(amount));
        // } else {
        //     assertEq(position.amount, int256(amount));
        // }
        console.logInt(position.amount);

        if (isShort) {
            assertLt(position.amount, 0);
        } else {
            assertGt(position.amount, 0);
        }
        assertGt(position.entryPrice, 0);
    }

    function testDeposit() public {
        vm.prank(address(controller));
        daiVault.deposit(receiver, 100 * 10 ** 8, 0, block.timestamp + 100);
    }

    function testChangeOraclePrice() public {
        uint256 newPrice = 2000;
        mockPerpDex.changeOraclePrice(address(vault), newPrice);

        assertEq(mockPerpDex.priceOracle(address(vault)), newPrice);
    }
}
