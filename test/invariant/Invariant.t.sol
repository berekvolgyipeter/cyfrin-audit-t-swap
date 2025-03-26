// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import { Test, StdInvariant } from "forge-std/Test.sol";
import { ERC20Mock } from "@openzeppelin/contracts/mocks/token/ERC20Mock.sol";

import { PoolFactory } from "../../src/PoolFactory.sol";
import { TSwapPool } from "../../src/TSwapPool.sol";

import { TSwapPoolHandler } from "./TSwapPoolHandler.sol";

contract Invariant is StdInvariant, Test {
    PoolFactory factory;
    TSwapPool pool;
    ERC20Mock weth;
    ERC20Mock poolToken;

    int256 constant STARTING_X = 50e18; // starting WETH
    int256 constant STARTING_Y = 100e18; // starting ERC20
    uint256 constant FEE = 997e15;
    int256 constant MATH_PRECISION = 1e18;

    TSwapPoolHandler handler;

    function setUp() public {
        weth = new ERC20Mock();
        poolToken = new ERC20Mock();
        factory = new PoolFactory(address(weth));
        pool = TSwapPool(factory.createPool(address(poolToken)));

        // Create the initial x & y values for the pool
        weth.mint(address(this), uint256(STARTING_X));
        poolToken.mint(address(this), uint256(STARTING_Y));

        weth.approve(address(pool), type(uint256).max);
        poolToken.approve(address(pool), type(uint256).max);
        pool.deposit(uint256(STARTING_X), uint256(STARTING_X), uint256(STARTING_Y), uint64(block.timestamp));

        handler = new TSwapPoolHandler(pool);

        targetContract(address(handler));
    }
}
