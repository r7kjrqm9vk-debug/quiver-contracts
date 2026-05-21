// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/QuiverToken.sol";

contract DeployToken is Script {
    function run() external {
        uint256 deployerKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerKey);

        QuiverToken token = new QuiverToken();
        console.log("QuiverToken deployed at:", address(token));

        vm.stopBroadcast();
    }
}
