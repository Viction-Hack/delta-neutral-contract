// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Ownable} from "openzeppelin-contracts/contracts/access/Ownable.sol";
import {ReentrancyGuard} from "openzeppelin-contracts/contracts/utils/ReentrancyGuard.sol";
import {IERC20} from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {IVault} from "../interfaces/IVault.sol";
import {IDoldrumsGateway} from "../interfaces/IDoldrumsGateway.sol";
import {IController} from "../interfaces/IController.sol";

contract Vault is Ownable, ReentrancyGuard, IVault {
    address public controller;
    address public underlying;
    address public doldrumsGateway;
    uint256 public mintedDUSDCAmount;

    constructor(address _controller, address _doldrumsGateway, address _underyling) Ownable(msg.sender) {
        controller = _controller;
        doldrumsGateway = _doldrumsGateway;
        underlying = _underyling;
    }

    modifier onlyController() {
        require(msg.sender == controller, "Vault: not controller");
        _;
    }

    function deposit(address receiver, uint256 collateralAmountIn, uint256 minDUSDCAmountOut, uint256 deadline)
        external
        onlyController
    {
        _placePerpOrder(
            receiver,
            collateralAmountIn,
            minDUSDCAmountOut,
            deadline,
            true // short
        );
    }

    function redeem(address receiver, uint256 dusdAmountIn, uint256 minCollateralAmountOut, uint256 deadline)
        external
        onlyController
    {
        require(dusdAmountIn <= mintedDUSDCAmount, "Vault: dusdAmountIn exceed mintedDUSDCAmount");
        _placePerpOrder(
            receiver,
            dusdAmountIn,
            minCollateralAmountOut,
            deadline,
            false // long
        );
    }

    function _placePerpOrder(address receiver, uint256 amountIn, uint256 minAmountOut, uint256 deadline, bool isShort)
        private
    {
        if (isShort) {
            IERC20(underlying).approve(doldrumsGateway, amountIn);
        }
        IDoldrumsGateway(doldrumsGateway).openPositionFor(
            isShort, address(this), receiver, amountIn, minAmountOut, deadline
        );

        emit PositionRequested(receiver, amountIn, minAmountOut, deadline, isShort);
    }

    function receivePerpOrder(
        bool success,
        bool isShort,
        address receiver,
        uint256 excutedAmountOut,
        uint256 orginAmountIn,
        uint256 remainAmount,
        uint256 excutedPrice,
        uint256 excutedFee
    ) external {
        require(msg.sender == doldrumsGateway, "Vault: not doldrumsGateway");
        if (isShort) {
            // mint
            if (success) {
                mintedDUSDCAmount += excutedAmountOut;
            }
            IController(controller)._mintAfterVault(success, receiver, orginAmountIn, excutedAmountOut, remainAmount);
        } else {
            // redeem
            if (success) {
                mintedDUSDCAmount -= (orginAmountIn - remainAmount);
                // if(underlying == address(0)) {
                //     payable(receiver).transfer(excutedAmountOut);
                // } else {
                //     // *Must need to approve, receive collateral from doldrumsGateway and transfer to receiver
                //     IERC20(underlying).transferFrom(doldrumsGateway, receiver, excutedAmountOut);
                // }
                // IERC20(underlying).transferFrom(doldrumsGateway, controller, excutedAmountOut);
            }
            IController(controller)._redeemAfterVault(success, receiver, orginAmountIn, excutedAmountOut, remainAmount);
        }
        emit PositionExecuted(
            success, isShort, receiver, excutedAmountOut, orginAmountIn, remainAmount, excutedPrice, excutedFee
        );
    }
}
