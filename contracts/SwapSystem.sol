// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma abicoder v2;

import "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";
import "@uniswap/v3-periphery/contracts/libraries/TransferHelper.sol";

contract SwapSystem {
    ISwapRouter public immutable swapRouter;

    // For this example, we will set the pool fee to 0.3%.
    uint24 public constant poolFee = 3000;

    //https://github.com/Uniswap/v3-periphery/blob/main/contracts/SwapRouter.sol
    //https://docs.uniswap.org/protocol/reference/periphery/SwapRouter
    constructor(ISwapRouter _swapRouter) {
        swapRouter = _swapRouter;
    }

    function swapExactInputSingle(
        address token1,
        address token2,
        uint256 amountIn
    ) external returns (uint256 amountOut) {
        TransferHelper.safeApprove(token1, address(swapRouter), amountIn);
        TransferHelper.safeTransferFrom(
            token1,
            msg.sender,
            address(this),
            amountIn
        );

        // Naively set amountOutMinimum to 0. In production, use an oracle or other data source to
        //choose a safer value for amountOutMinimum.
        // We also set the sqrtPriceLimitx96 to be 0 to ensure we swap our exact input amount.
        ISwapRouter.ExactInputSingleParams memory params = ISwapRouter
            .ExactInputSingleParams({
                tokenIn: token1,
                tokenOut: token2,
                fee: poolFee,
                recipient: msg.sender,
                deadline: block.timestamp,
                amountIn: amountIn,
                amountOutMinimum: 0,
                sqrtPriceLimitX96: 0
            });

        amountOut = swapRouter.exactInputSingle(params);
    }

    function swapExactOutputSingle(
        address token1,
        address token2,
        uint256 amountOut,
        uint256 amountInMaximum
    ) external returns (uint256 amountIn) {
        // Approve the router to spend the specified `amountInMaximum` of token1.
        // In production, you should choose the maximum amount to spend based on oracles or other data sources to achieve a better swap.
        TransferHelper.safeApprove(
            token1,
            address(swapRouter),
            amountInMaximum
        );

        TransferHelper.safeTransferFrom(
            token1,
            msg.sender,
            address(this),
            amountInMaximum
        );

        ISwapRouter.ExactOutputSingleParams memory params = ISwapRouter
            .ExactOutputSingleParams({
                tokenIn: token1,
                tokenOut: token2,
                fee: poolFee,
                recipient: msg.sender,
                deadline: block.timestamp,
                amountOut: amountOut,
                amountInMaximum: amountInMaximum,
                sqrtPriceLimitX96: 0
            });

        // Executes the swap returning the amountIn needed to spend to receive the desired amountOut.
        amountIn = swapRouter.exactOutputSingle(params);

        // For exact output swaps, the amountInMaximum may not have all been spent.
        // If the actual amount spent (amountIn) is less than the specified maximum amount, we must refund the msg.sender and approve the swapRouter to spend 0.
        if (amountIn < amountInMaximum) {
            TransferHelper.safeApprove(token1, address(swapRouter), 0);
            TransferHelper.safeTransfer(
                token1,
                msg.sender,
                amountInMaximum - amountIn
            );
        }
    }
}
