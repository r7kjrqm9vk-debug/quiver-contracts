// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./QuiverToken.sol";

/**
 * @title QuiverFaucet
 * @notice Distributes 100 QVR every 24h per wallet
 * @dev Tracks unique users for Quiver Protocol stats
 */
contract QuiverFaucet is Ownable {
    QuiverToken public immutable token;

    uint256 public constant CLAIM_AMOUNT = 100 * 1e18;
    uint256 public constant COOLDOWN = 24 hours;

    mapping(address => uint256) public lastClaim;
    mapping(address => bool) public hasInteracted;
    address[] public uniqueUsers;
    uint256 public totalClaims;

    event Claimed(address indexed user, uint256 amount, uint256 timestamp);

    constructor(address _token) Ownable(msg.sender) {
        token = QuiverToken(_token);
    }

    function claim() external {
        require(
            block.timestamp >= lastClaim[msg.sender] + COOLDOWN,
            "Cooldown active"
        );

        lastClaim[msg.sender] = block.timestamp;
        totalClaims++;

        if (!hasInteracted[msg.sender]) {
            hasInteracted[msg.sender] = true;
            uniqueUsers.push(msg.sender);
        }

        token.mint(msg.sender, CLAIM_AMOUNT);

        emit Claimed(msg.sender, CLAIM_AMOUNT, block.timestamp);
    }

    function uniqueUsersCount() external view returns (uint256) {
        return uniqueUsers.length;
    }

    function canClaim(address user) external view returns (bool) {
        return block.timestamp >= lastClaim[user] + COOLDOWN;
    }

    function nextClaimTime(address user) external view returns (uint256) {
        return lastClaim[user] + COOLDOWN;
    }
}
