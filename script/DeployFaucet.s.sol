// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/QuiverFaucet.sol";
import "../src/QuiverToken.sol";

contract DeployFaucet is Script {
    address constant QUIVER_TOKEN = 0xd8690c73988C593033De284A0eEeD6bCf5C1ef25;

    function run() external {
        uint256 deployerKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerKey);

        QuiverFaucet faucet = new QuiverFaucet(QUIVER_TOKEN);
        console.log("QuiverFaucet deployed at:", address(faucet));

        // Collega il faucet al token
        QuiverToken(QUIVER_TOKEN).setFaucet(address(faucet));
        console.log("Faucet set on QuiverToken");

        vm.stopBroadcast();
    }
}
