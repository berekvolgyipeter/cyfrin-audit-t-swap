// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import { Test, console2 } from "forge-std/Test.sol";
import { TSwapPool } from "../../src/TSwapPool.sol";
import { ERC20Mock } from "@openzeppelin/contracts/mocks/token/ERC20Mock.sol";

contract TSwapPoolHandler is Test {
    TSwapPool pool;
    ERC20Mock weth;
    ERC20Mock poolToken;

    address liquidityProvider = makeAddr("liquidityProvider");
    address user = makeAddr("user");

    // Ghost variables
    int256 public deltaX;
    int256 public expDeltaX;

    int256 public deltaY;
    int256 public expDeltaY;

    int256 public startingX;
    int256 public startingY;

    constructor(TSwapPool _pool) {
        pool = _pool;
        weth = ERC20Mock(pool.getWeth());
        poolToken = ERC20Mock(pool.getPoolToken());
    }

    function deposit(uint256 wethAmount) public {
        // make the amount to deposit a "reasonable" number. We wouldn't expect someone to have type(uint256).max WETH
        wethAmount = bound(wethAmount, pool.getMinimumWethDepositAmount(), type(uint64).max);
        uint256 poolTokenAmount = pool.getPoolTokensToDepositBasedOnWeth(wethAmount);

        _updateStartingDeltas(int256(wethAmount), int256(poolTokenAmount));

        vm.startPrank(liquidityProvider);
        weth.mint(liquidityProvider, wethAmount);
        poolToken.mint(liquidityProvider, poolTokenAmount);

        weth.approve(address(pool), wethAmount);
        poolToken.approve(address(pool), poolTokenAmount);

        pool.deposit({
            wethToDeposit: wethAmount,
            minimumLiquidityTokensToMint: 0,
            maximumPoolTokensToDeposit: poolTokenAmount,
            deadline: uint64(block.timestamp)
        });
        vm.stopPrank();

        _updateEndingDeltas();
    }

    /*//////////////////////////////////////////////////////////////
                    HELPER FUNCTIONS
    //////////////////////////////////////////////////////////////*/
    function _updateStartingDeltas(int256 wethAmount, int256 poolTokenAmount) internal {
        startingX = int256(weth.balanceOf(address(pool)));
        startingY = int256(poolToken.balanceOf(address(pool)));

        expDeltaX = wethAmount;
        expDeltaY = poolTokenAmount;
    }

    function _updateEndingDeltas() internal {
        uint256 endingX = weth.balanceOf(address(pool));
        uint256 endingY = poolToken.balanceOf(address(pool));

        deltaX = int256(endingX) - int256(startingX);
        deltaY = int256(endingY) - int256(startingY);
    }
}
