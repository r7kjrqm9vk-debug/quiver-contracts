// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/QuiverFactory.sol";
import "../src/QuiverToken.sol";

contract CreatePools is Script {
    address constant QUIVER_TOKEN   = 0xd8690c73988C593033De284A0eEeD6bCf5C1ef25;
    address constant QUIVER_FACTORY = 0x68c89b8d5B860A08a884d1A0C833Baf8F241c8F1;

    // Stock Tokens Robinhood Chain
    address constant TSLA = 0xC9f9c86933092BbbfFF3CCb4b105A4A94bf3Bd4E;
    address constant AMD  = 0x71178BAc73cBeb415514eB542a8995b82669778d;
    address constant AMZN = 0x5884aD2f920c162CFBbACc88C9C51AA75eC09E02;
    address constant NFLX = 0x3b8262A63d25f0477c4DDE23F83cfe22Cb768C93;
    address constant PLTR = 0x1FBE1a0e43594b3455993B5dE5Fd0A7A266298d0;

    function run() external {
        uint256 deployerKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerKey);

        QuiverToken token = QuiverToken(QUIVER_TOKEN);
        QuiverFactory factory = QuiverFactory(QUIVER_FACTORY);

        // Approve Factory a spendere QVR per i burn
        // 5 pool × 10 QVR = 50 QVR totali
        token.approve(QUIVER_FACTORY, 50 * 1e18);
        console.log("QVR approved");

        address p1 = factory.createPool(TSLA, AMD,  "TSLA", "AMD");
        console.log("TSLA/AMD pool:", p1);

        address p2 = factory.createPool(TSLA, AMZN, "TSLA", "AMZN");
        console.log("TSLA/AMZN pool:", p2);

        address p3 = factory.createPool(AMZN, NFLX, "AMZN", "NFLX");
        console.log("AMZN/NFLX pool:", p3);

        address p4 = factory.createPool(AMD,  PLTR, "AMD",  "PLTR");
        console.log("AMD/PLTR pool:", p4);

        address p5 = factory.createPool(TSLA, NFLX, "TSLA", "NFLX");
        console.log("TSLA/NFLX pool:", p5);

        vm.stopBroadcast();
    }
}
