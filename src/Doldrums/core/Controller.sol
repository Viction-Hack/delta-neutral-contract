// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract Controller is Ownable {

    function mint(
        address assetToken,
        uint256 assetAmount,
        uint256 minAmountOut,
        address receiver
    ) external nonReentrant returns (uint256) {
        // 1. check that token is approved
        // 2. get clearing house from router
        // 3. transfer tokens from msg.sender to clearing house
        // 4. execute perp tx
        // 6. mint
        IERC20Upgradeable collateral = IERC20Upgradeable(assetToken);
        address account = msg.sender;
        if(collateral.allowance(account, address(this)) < assetAmount) {
            revert CtrlNotApproved(assetToken, account, assetAmount);
        }

        address depository = router.findDepositoryForDeposit(assetToken, assetAmount);
        collateral.safeTransferFrom(
            account,
            depository,
            assetAmount
        );

        InternalMintParams memory mintParams = InternalMintParams({
            assetToken: assetToken,
            assetAmount: assetAmount,
            minAmountOut: minAmountOut,
            receiver: receiver,
            depository: depository
        });
        return _mint(mintParams);
    }

    /// @notice Mints UXD with ETH as collateral.
    /// @dev Contract wraps ETH to WETH and deposits WETH in DEX vault
    function mintWithEth(uint256 minAmountOut, address receiver)
        external
        payable
        nonReentrant
        returns (uint256)
    {
        uint256 amount = msg.value;
        address collateral = weth;
        address depository = router.findDepositoryForDeposit(collateral, amount);

        // Deposit ETH with WETH contract and mint WETH
        IWETH9(weth).deposit{value: amount}();
        IERC20Upgradeable(weth).safeTransfer(depository, amount);
        InternalMintParams memory mintParams = InternalMintParams({
            assetToken: collateral,
            assetAmount: msg.value,
            minAmountOut: minAmountOut,
            receiver: receiver,
            depository: depository
        });
        return _mint(mintParams);
    }

    /// @dev internal mint function
    function _mint(InternalMintParams memory mintParams)
        internal
        returns (uint256)
    {
        if (!whitelistedAssets[mintParams.assetToken]) {
            revert CtrlNotWhitelisted(mintParams.assetToken);
        }
        uint256 amountOut = IDepository(mintParams.depository).deposit(
            mintParams.assetToken, 
            mintParams.assetAmount
        );

        if (amountOut < mintParams.minAmountOut) {
            revert CtrlMinNotMet(mintParams.minAmountOut, amountOut);
        }
        redeemable.mint(mintParams.receiver, amountOut);
        emit Minted(msg.sender, mintParams.receiver, amountOut);

        return amountOut;
    }

    /// @notice Redeems a given amount of redeemable token.
    /// @param assetToken the token to receive by redeeming.
    /// @param redeemAmount The amount to redeemable token being redeemed.
    /// @param minAmountOut The min amount of `assetToken` to receive.
    /// @param receiver The account to receive assets
    function redeem(
        address assetToken,
        uint256 redeemAmount,
        uint256 minAmountOut,
        address receiver
    ) external nonReentrant returns (uint256) {
        InternalRedeemParams memory rp = InternalRedeemParams({
            assetToken: assetToken,
            amountToRedeem: redeemAmount,
            minAmountOut: minAmountOut,
            intermediary: receiver
        });
        uint256 amountOut = _redeem(rp);
        emit Redeemed(msg.sender, receiver, amountOut);
        return amountOut;
    }

    function redeemForEth(
        uint256 redeemAmount,
        uint256 minAmonuntOut,
        address payable receiver
    ) external nonReentrant returns (uint256) {
        // 1. redeem WETH to controller
        // 2. unwrap ETH
        // 3. Transfer ETH to user

        InternalRedeemParams memory rp = InternalRedeemParams({
            assetToken: weth,
            amountToRedeem: redeemAmount,
            minAmountOut: minAmonuntOut,
            intermediary: address(this)
        });

        uint256 amountOut = _redeem(rp);

        // withdraw ETH from WETH contract by burning WETH.
        // ETH is withdrawn to the caller (this contract), and can then be sent to the msg.sender
        // from this contract.
        IWETH9(weth).withdraw(amountOut);
        // solhint-disable-next-line avoid-low-level-calls
        (bool success,) = receiver.call{value: amountOut}("");
        require(success, "ETH transfer failed");

        emit Redeemed(msg.sender, receiver, amountOut);
        return amountOut;
    }

    /// @dev internal redeem function
    function _redeem(InternalRedeemParams memory redeemParams)
        internal
        returns (uint256)
    {
        if(redeemable.allowance(msg.sender, address(this)) < redeemParams.amountToRedeem) {
            revert CtrlNotApproved(address(redeemable), msg.sender, redeemParams.amountToRedeem);
        }
        
        address depository = router.findDepositoryForRedeem(
            redeemParams.assetToken,
            redeemParams.amountToRedeem
        );

        uint256 amountOut = IDepository(depository).redeem(
            redeemParams.assetToken, 
            redeemParams.amountToRedeem
        );

        if (amountOut < redeemParams.minAmountOut) {
            revert CtrlMinNotMet(redeemParams.minAmountOut, amountOut);
        }
        redeemable.burn(msg.sender, redeemParams.amountToRedeem);
        IERC20Upgradeable(redeemParams.assetToken).safeTransfer(redeemParams.intermediary, amountOut);

        return amountOut;
    }

}
