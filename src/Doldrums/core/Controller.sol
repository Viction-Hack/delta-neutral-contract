// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IController} from "../interfaces/IController.sol";
import {Ownable} from "openzeppelin-contracts/contracts/access/Ownable.sol";
import {ReentrancyGuard} from "openzeppelin-contracts/contracts/utils/ReentrancyGuard.sol";
import {DUSD} from "../dusd/DUSD.sol";
import {INativeOFTV2} from "../interfaces/INativeOFTV2.sol";
import {IVault} from "../interfaces/IVault.sol";
import {IERC20} from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

contract Controller is IController, Ownable, ReentrancyGuard {
    DUSD public dusd;

    address public vic;
    mapping(address => address) private underlyingToVault; // underlying => vault
    mapping(address => address) private valutToUnderlying; // vault => underlying

    constructor(address _vic) Ownable(msg.sender) {
        vic = _vic;
    }

    function setDUSD(address _dusd) external onlyOwner {
        dusd = DUSD(_dusd);
    }

    function registerVault(address underlying, address vault) external onlyOwner {
        underlyingToVault[underlying] = vault;
        valutToUnderlying[vault] = underlying;
    }

    function mint(
        address underlying,
        address receiver,
        uint256 collateralAmountIn,
        uint256 minDUSDCAmountOut,
        uint256 deadline
    ) external nonReentrant {
        // 1. check that token is approved
        // 2. get clearing house from router
        // 3. transfer tokens from msg.sender to clearing house
        // 4. execute perp tx
        // 6. mint
        IERC20 collateral = IERC20(underlying);
        address account = msg.sender;
        if (collateral.allowance(account, address(this)) < collateralAmountIn) {
            revert NotApproved(underlying, account, collateralAmountIn);
        }

        address vault = underlyingToVault[underlying];
        collateral.transferFrom(account, vault, collateralAmountIn);

        _mint(vault, receiver, collateralAmountIn, minDUSDCAmountOut, deadline);
        // IVault(vault).deposit(
        //     receiver,
        //     collateralAmountIn,
        //     minDUSDCAmountOut,
        //     deadline
        // );
    }

    function mintWithVic(address receiver, uint256 minDUSDCAmountOut, uint256 deadline) external payable nonReentrant {
        address vault = underlyingToVault[vic];

        // payable(vault).transfer(msg.value);
        INativeOFTV2(vic).deposit{value: msg.value}();
        IERC20(vic).transfer(vault, msg.value);
        _mint(vault, receiver, msg.value, minDUSDCAmountOut, deadline);
        // IVault(vault).deposit{value: msg.value}(
        //     receiver,
        //     msg.value,
        //     minDUSDCAmountOut,
        //     deadline
        // );
    }

    function _mint(
        address vault,
        address receiver,
        uint256 collateralAmountIn,
        uint256 minDUSDCAmountOut,
        uint256 deadline
    ) internal {
        IVault(vault).deposit(receiver, collateralAmountIn, minDUSDCAmountOut, deadline);
    }

    function _mintAfterVault(
        bool success,
        address receiver,
        uint256 collateralAmountIn,
        uint256 excutedDUSDCAmountOut,
        uint256 remainAmount
    ) external {
        address underlying = valutToUnderlying[msg.sender];
        require(underlying != address(0), "Controller: msg.sender is not a registered vault");

        if (!success) {
            _transfer(underlying, receiver, collateralAmountIn);
            emit MintFailed(receiver, collateralAmountIn);
            return;
        }
        if (remainAmount > 0) {
            _transfer(underlying, receiver, remainAmount);
        }

        dusd.mint(receiver, excutedDUSDCAmountOut);
        emit Minted(receiver, collateralAmountIn, excutedDUSDCAmountOut, remainAmount);
    }

    function redeem(
        address underlying,
        address receiver,
        uint256 dusdAmountIn,
        uint256 minCollateralAmountOut,
        uint256 deadline
    ) external nonReentrant {
        if (dusd.allowance(msg.sender, address(this)) < dusdAmountIn) {
            revert NotApproved(address(dusd), msg.sender, dusdAmountIn);
        }

        address vault = underlyingToVault[underlying];

        IVault(vault).redeem(receiver, dusdAmountIn, minCollateralAmountOut, deadline);
    }

    function _redeemAfterVault(
        bool success,
        address receiver,
        uint256 dusdAmountIn,
        uint256 excutedCollateralAmountOut,
        uint256 remainAmount
    ) external {
        address underlying = valutToUnderlying[msg.sender];
        require(underlying != address(0), "Controller: msg.sender is not a registered vault");

        if (!success) {
            dusd.transfer(receiver, dusdAmountIn);
            emit RedeemFailed(receiver, dusdAmountIn);
            return;
        }
        if (remainAmount > 0) {
            dusd.transfer(receiver, remainAmount);
        }
        _transfer(underlying, receiver, excutedCollateralAmountOut);

        dusd.burn(receiver, dusdAmountIn - remainAmount);
        emit Redeemed(receiver, dusdAmountIn - remainAmount, excutedCollateralAmountOut, remainAmount);
    }

    function _transfer(address token, address receiver, uint256 amount) internal {
        if (token == vic) {
            INativeOFTV2(vic).withdraw(receiver, amount);
        } else {
            IERC20(token).transfer(receiver, amount);
        }
    }
}
