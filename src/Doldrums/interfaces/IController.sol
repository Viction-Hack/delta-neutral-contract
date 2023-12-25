// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;


interface IController {


    // frontend functions 
    function mint(
        address underlying,
        address receiver,
        uint256 collateralAmountIn,
        uint256 minDUSDCAmountOut,
        uint256 deadline
    ) external;

    function mintWithVic(address receiver, uint256 minDUSDCAmountOut, uint256 deadline) external payable;
    
    function redeem(
        address underlying,
        address receiver,
        uint256 dusdAmountIn,
        uint256 minCollateralAmountOut,
        uint256 deadline
    ) external;
    // end frontend functions

    function _mintAfterVault(bool success, address receiver, uint256 collateralAmountIn, uint256 excutedDUSDCAmountOut, uint256 excutedPrice) external;
    function _redeemAfterVault(bool success, address receiver, uint256 dusdAmountIn, uint256 excutedCollateralAmountOut, uint256 excutedPrice) external;

    error NotApproved(address token, address account, uint256 amount);
    event Minted(address indexed receiver, uint256 collateralAmountIn, uint256 excutedDUSDCAmountOut, uint256 remainAmount);
    event MintFailed(address indexed receiver, uint256 collateralAmountIn);
    event Redeemed(address indexed receiver, uint256 dusdAmountIn, uint256 executedCollateralAmountOut, uint256 remainAmount);
    event RedeemFailed(address indexed receiver, uint256 dusdAmountIn);
}