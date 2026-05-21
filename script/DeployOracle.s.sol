// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/QuiverOracle.sol";

contract DeployOracle is Script {
    function run() external {
        uint256 deployerKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerKey);

        QuiverOracle oracle = new QuiverOracle();
        console.log("QuiverOracle deployed at:", address(oracle));

        string[] memory syms = new string[](5);
        uint256[] memory prices = new uint256[](5);
        syms[0] = "TSLA"; prices[0] = 25000000000;
        syms[1] = "AMD";  prices[1] = 10800000000;
        syms[2] = "AMZN"; prices[2] = 19500000000;
        syms[3] = "NFLX"; prices[3] = 98000000000;
        syms[4] = "PLTR"; prices[4] = 2800000000;

        oracle.updatePrices(syms, prices);
        console.log("Prices seeded");

        vm.stopBroadcast();
    }
}
