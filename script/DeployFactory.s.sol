// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/QuiverFactory.sol";

contract DeployFactory is Script {
    address constant QUIVER_TOKEN  = 0xd8690c73988C593033De284A0eEeD6bCf5C1ef25;
    address constant QUIVER_ORACLE = 0xF2b1DcB76C26ec79EB240CDBb3E0a2E0c3403A3a;

    function run() external {
        uint256 deployerKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerKey);

        QuiverFactory factory = new QuiverFactory(QUIVER_TOKEN, QUIVER_ORACLE);
        console.log("QuiverFactory deployed at:", address(factory));

        // Setta il rewardPool sul token
        QuiverToken(QUIVER_TOKEN).setRewardPool(address(factory));
        console.log("RewardPool set on QuiverToken");

        vm.stopBroadcast();
    }
}
