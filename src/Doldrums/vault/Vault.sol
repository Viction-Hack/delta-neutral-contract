// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Ownable} from "openzeppelin-contracts/contracts/access/Ownable.sol";
import {ReentrancyGuard} from "openzeppelin-contracts/contracts/utils/ReentrancyGuard.sol";
import {IERC20} from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {IVault} from "../interfaces/IVault.sol";
import {IPerpDex} from "../interfaces/IPerpDex.sol";
import {IController} from "../interfaces/IController.sol";

contract Vault is Ownable, ReentrancyGuard, IVault {
    address public controller;
    address public underlying;
    address public perpDex;
    uint256 public collateralBalance;

    constructor(address _controller, address _perpDex, address _underyling) Ownable(msg.sender) {
        controller = _controller;
        perpDex = _perpDex;
        underlying = _underyling;
    }

    modifier onlyController() {
        require(msg.sender == controller, "Vault: not controller");
        _;
    }

    function deposit(
        address receiver,
        uint256 collateralAmountIn,
        uint256 minDUSDCAmountOut,
        uint256 deadline
    ) external onlyController {
        _placePerpOrder(
            receiver,
            collateralAmountIn,
            minDUSDCAmountOut,
            deadline,
            true // short
        );
    }

    function redeem(
        address receiver,
        uint256 dusdAmountIn,
        uint256 minCollateralAmountOut,
        uint256 deadline
    ) external onlyController {
        _placePerpOrder(
            receiver,
            dusdAmountIn,
            minCollateralAmountOut,
            deadline,
            false // long
        );
    }

    function _placePerpOrder(
        address receiver,
        uint256 amountIn,
        uint256 minAmountOut,
        uint256 deadline,
        bool isShort
    ) private {
        
        IPerpDex(perpDex).openPositionFor(
            address(this),
            receiver,
            amountIn,
            minAmountOut,
            deadline,
            isShort
        ); 

        emit PositionRequested(receiver, amountIn, minAmountOut, deadline, isShort);
    }

    function _receivePerpOrder(
        bool success,
        bool isShort,
        address receiver,
        uint256 excutedAmountOut,
        uint256 orginAmountIn,
        uint256 remainAmount,
        uint256 excutedPrice,
        uint256 feeAmount
    ) external {
        require (msg.sender == perpDex, "Vault: not perpDex");
        if (isShort) { // mint
            if(success){
                collateralBalance += orginAmountIn-remainAmount;
            }
            IController(controller)._mintAfterVault(success, receiver, orginAmountIn, excutedAmountOut, remainAmount);
        } else { // redeem
            if(success){
                collateralBalance -= excutedAmountOut;
                if(underlying == address(0)) {
                    payable(receiver).transfer(excutedAmountOut);
                } else {
                    IERC20(underlying).transfer(receiver, excutedAmountOut);
                }
            }
            IController(controller)._redeemAfterVault(success, receiver, orginAmountIn, excutedAmountOut, remainAmount);
        }
        emit PositionExecuted(success, isShort, receiver, excutedAmountOut, orginAmountIn, remainAmount, excutedPrice, feeAmount);
    }
}

