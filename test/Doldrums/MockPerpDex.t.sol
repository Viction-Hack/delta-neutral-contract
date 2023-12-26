// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "./Fixture.t.sol";
import "../../src/Doldrums/perpdex/MockPerpDex.sol";
import {Vault} from "../../src/Doldrums/vault/Vault.sol";
import {Controller} from "../../src/Doldrums/core/Controller.sol";

contract MockPerpDexTest is Test, Fixture {
    Controller controller;
    MockPerpDex mockPerpDex;
    DUSD dusd;
    MOCKOFTV2 weth;
    MOCKOFTV2 dai;
    Vault vault;
    Vault vicVault;
    Vault wethVault;
    Vault daiVault;
    address receiver;
    address lzEndpoint;

    function setUp() public {
        super.setUp();
        mockPerpDex = new MockPerpDex();
        address gateway = makeAddr("gateway");
        lzEndpoint = makeAddr("lzEndpoint");
        vault = new Vault(address(controller), address(mockPerpDex), address(0x0));
        dusd = new DUSD(address(controller),lzEndpoint);
        dai = new MOCKOFTV2("DAI","DAI",8,lzEndpoint);
        weth = new MOCKOFTV2("WETH","WETH",8,lzEndpoint);
        vicVault = new Vault(address(controller),address(mockPerpDex),address(wvic));
        daiVault = new Vault(address(controller),address(mockPerpDex),address(dai));
        wethVault = new Vault(address(controller),address(mockPerpDex),address(weth));
        controller.setDUSD(address(dusd));
        controller.registerVault(address(wvic), address(vicVault));
        controller.registerVault(address(dai), address(daiVault));
        controller.registerVault(address(weth), address(wethVault));

        receiver = address(this);

        mockPerpDex.changeOraclePrice(address(vault), 3000); // 1000 USD로 설정
    }

    function testOpenPosition() public {
        uint256 amount = 10 ether;
        uint256 minAmountOut = 9 * 3000;
        uint256 deadline = block.timestamp + 1 hours;
        bool isShort = true;

        mockPerpDex.openPositionFor(address(vault), receiver, amount, minAmountOut, deadline, isShort);

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

    function testMintWithVic() public {
        vm.startPrank(user1);
        vm.deal(user1, 100 ether);
        controller.mintWithVic{value: 100 ether}(user1, 100, block.timestamp + 100);
        console.log("user1 dusd balance : ", dusd.balanceOf(user1));
        vm.stopPrank();
    }

    function testMintWithERC20() public {
        vm.startPrank(user1);
        mockOFTV2.mint(user1, 100 * 10 ** 8);
        mockOFTV2.approve(address(controller), 100 * 10 ** 8);
        controller.mint(address(mockOFTV2), user1, 100 * 10 ** 8, 100, block.timestamp + 100);
        console.log("user1 dusd balance : ", dusd.balanceOf(user1));
        vm.stopPrank();
    }
}
