// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../../src/Doldrums/perpdex/MockPerpDex.sol"; // 경로는 실제 구조에 따라 조정하세요
import {Vault} from "../../src/Doldrums/vault/Vault.sol"; // Vault 컨트랙트의 경로도 실제 구조에 맞게 조정하세요

contract MockPerpDexTest is Test {
    MockPerpDex mockPerpDex;
    Vault vault;
    address receiver;

    function setUp() public {
        mockPerpDex = new MockPerpDex();
        vault = new Vault(address(0x0), address(mockPerpDex), address(0x0));

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
}
