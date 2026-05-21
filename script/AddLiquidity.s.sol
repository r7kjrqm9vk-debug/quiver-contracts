// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/QuiverPool.sol";
import "../src/QuiverToken.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract AddLiquidity is Script {
    address constant QUIVER_TOKEN = 0xd8690c73988C593033De284A0eEeD6bCf5C1ef25;

    address constant TSLA = 0xC9f9c86933092BbbfFF3CCb4b105A4A94bf3Bd4E;
    address constant AMD  = 0x71178BAc73cBeb415514eB542a8995b82669778d;
    address constant AMZN = 0x5884aD2f920c162CFBbACc88C9C51AA75eC09E02;
    address constant NFLX = 0x3b8262A63d25f0477c4DDE23F83cfe22Cb768C93;
    address constant PLTR = 0x1FBE1a0e43594b3455993B5dE5Fd0A7A266298d0;

    // tokenA => tokenB (ordine canonico verificato on-chain)
    address constant POOL_AMZN_TSLA = 0x6C2fC2923f225A207F26E380cda1eceC09d4FFE7; // A=AMZN B=TSLA
    address constant POOL_NFLX_AMZN = 0x8A7564CB7638767dfEB703C9050f19E1C398c325; // A=NFLX B=AMZN
    address constant POOL_PLTR_AMD  = 0x6879852c5DA24993e76d8C69A4ADa942Cb76Eb89; // A=PLTR B=AMD
    address constant POOL_NFLX_TSLA = 0x5f8021925EB18B9243f8616A4547492e6c993bA2; // A=NFLX B=TSLA

    function run() external {
        uint256 deployerKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerKey);

        QuiverToken qvr = QuiverToken(QUIVER_TOKEN);

        qvr.approve(POOL_AMZN_TSLA, 5 * 1e18);
        qvr.approve(POOL_NFLX_AMZN, 5 * 1e18);
        qvr.approve(POOL_PLTR_AMD,  5 * 1e18);
        qvr.approve(POOL_NFLX_TSLA, 5 * 1e18);

        // AMZN/TSLA: 13 AMZN + 10 TSLA
        _addLiquidity(POOL_AMZN_TSLA, AMZN, TSLA, 13 * 1e18, 10 * 1e18);
        console.log("AMZN/TSLA liquidity added");

        // NFLX/AMZN: 2 NFLX + 10 AMZN
        _addLiquidity(POOL_NFLX_AMZN, NFLX, AMZN, 2 * 1e18, 10 * 1e18);
        console.log("NFLX/AMZN liquidity added");

        // PLTR/AMD: 38 PLTR + 10 AMD
        _addLiquidity(POOL_PLTR_AMD, PLTR, AMD, 38 * 1e18, 10 * 1e18);
        console.log("PLTR/AMD liquidity added");

        // NFLX/TSLA: 10 NFLX + 38 TSLA
        _addLiquidity(POOL_NFLX_TSLA, NFLX, TSLA, 10 * 1e18, 38 * 1e18);
        console.log("NFLX/TSLA liquidity added");

        vm.stopBroadcast();
    }

    function _addLiquidity(
        address pool,
        address tokenA,
        address tokenB,
        uint256 amountA,
        uint256 amountB
    ) internal {
        IERC20(tokenA).approve(pool, amountA);
        IERC20(tokenB).approve(pool, amountB);
        QuiverPool(pool).addLiquidity(amountA, amountB);
    }
}
