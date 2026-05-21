// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./QuiverToken.sol";
import "./QuiverOracle.sol";
import "./QuiverPool.sol";

/**
 * @title QuiverFactory
 * @notice Deploys QuiverPool instances for Stock Token pairs
 * @dev Tracks unique users, manages RewardPool per pool
 */
contract QuiverFactory is Ownable {
    QuiverToken public immutable qvr;
    QuiverOracle public immutable oracle;

    // tokenA => tokenB => pool
    mapping(address => mapping(address => address)) public getPool;
    address[] public allPools;

    // Pool => reward accumulato in QVR
    mapping(address => uint256) public rewardPool;

    // Unique users tracker
    mapping(address => bool) public hasInteracted;
    address[] public uniqueUsers;
    uint256 public totalInteractions;

    // Burn costs
    uint256 public constant CREATE_POOL_COST = 10 * 1e18;

    event PoolCreated(address indexed tokenA, address indexed tokenB, address pool, uint256 index);
    event RewardAdded(address indexed pool, uint256 amount);
    event RewardPaid(address indexed pool, address indexed keeper, uint256 amount);

    constructor(address _qvr, address _oracle) Ownable(msg.sender) {
        qvr = QuiverToken(_qvr);
        oracle = QuiverOracle(_oracle);
    }

    function createPool(
        address tokenA,
        address tokenB,
        string calldata symbolA,
        string calldata symbolB
    ) external returns (address pool) {
        require(tokenA != tokenB, "Identical tokens");
        require(tokenA != address(0) && tokenB != address(0), "Zero address");

        // Ordine canonico
        (address t0, address t1, string memory s0, string memory s1) = tokenA < tokenB
            ? (tokenA, tokenB, symbolA, symbolB)
            : (tokenB, tokenA, symbolB, symbolA);

        require(getPool[t0][t1] == address(0), "Pool exists");

        // Burn 50% + 50% reward
        _splitBurn(msg.sender, CREATE_POOL_COST);

        pool = address(new QuiverPool(t0, t1, s0, s1, address(qvr), address(oracle), address(this)));

        getPool[t0][t1] = pool;
        getPool[t1][t0] = pool;
        allPools.push(pool);

        _trackUser();

        emit PoolCreated(t0, t1, pool, allPools.length - 1);
    }

    /// @notice Aggiunge reward al pool — chiamato da QuiverPool
    function addReward(address pool, uint256 amount) external {
        require(isValidPool(pool), "Invalid pool");
        rewardPool[pool] += amount;
        emit RewardAdded(pool, amount);
    }

    /// @notice Paga il keeper che ha chiamato rebalance()
    function payKeeper(address pool, address keeper) external {
        require(isValidPool(pool), "Invalid pool");
        require(msg.sender == pool, "Only pool");
        uint256 reward = rewardPool[pool];
        require(reward > 0, "No reward");
        rewardPool[pool] = 0;
        qvr.transfer(keeper, reward);
        emit RewardPaid(pool, keeper, reward);
    }

    function _splitBurn(address from, uint256 amount) internal {
        uint256 half = amount / 2;
        uint256 otherHalf = amount - half;
        // 50% burn reale
        qvr.transferFrom(from, address(0x000000000000000000000000000000000000dEaD), half);
        // 50% al Factory come reward reserve
        qvr.transferFrom(from, address(this), otherHalf);
    }

    function _trackUser() internal {
        totalInteractions++;
        if (!hasInteracted[msg.sender]) {
            hasInteracted[msg.sender] = true;
            uniqueUsers.push(msg.sender);
        }
    }

    function isValidPool(address pool) public view returns (bool) {
        for (uint256 i = 0; i < allPools.length; i++) {
            if (allPools[i] == pool) return true;
        }
        return false;
    }

    function getAllPools() external view returns (address[] memory) {
        return allPools;
    }

    function poolsCount() external view returns (uint256) {
        return allPools.length;
    }

    function uniqueUsersCount() external view returns (uint256) {
        return uniqueUsers.length;
    }
}
