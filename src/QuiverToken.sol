// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title QuiverToken
 * @notice $QVR — native token of Quiver Protocol on Robinhood Chain
 * @dev Minted only by Faucet. Burns split 50% to 0x000, 50% to RewardPool
 */
contract QuiverToken is ERC20, Ownable {
    address public faucet;
    address public rewardPool;

    uint256 public constant MAX_SUPPLY = 1_000_000 * 1e18;
    uint256 public totalBurned;

    event FaucetSet(address indexed faucet);
    event RewardPoolSet(address indexed rewardPool);
    event Burned(address indexed from, uint256 toZero, uint256 toReward);

    constructor() ERC20("Quiver", "QVR") Ownable(msg.sender) {}

    modifier onlyFaucet() {
        require(msg.sender == faucet, "Only faucet");
        _;
    }

    function setFaucet(address _faucet) external onlyOwner {
        faucet = _faucet;
        emit FaucetSet(_faucet);
    }

    function setRewardPool(address _rewardPool) external onlyOwner {
        rewardPool = _rewardPool;
        emit RewardPoolSet(_rewardPool);
    }

    /// @notice Mint called only by Faucet
    function mint(address to, uint256 amount) external onlyFaucet {
        require(totalSupply() + amount <= MAX_SUPPLY, "Max supply exceeded");
        _mint(to, amount);
    }

    /// @notice Split burn: 50% to 0x000, 50% to RewardPool
    function splitBurn(address from, uint256 amount) external {
        require(rewardPool != address(0), "RewardPool not set");
        uint256 half = amount / 2;
        uint256 otherHalf = amount - half;

        _burn(from, half);
        totalBurned += half;

        _transfer(from, rewardPool, otherHalf);

        emit Burned(from, half, otherHalf);
    }

    /// @notice Pure burn to 0x000
    function burn(uint256 amount) external {
        _burn(msg.sender, amount);
        totalBurned += amount;
    }

    function remainingSupply() external view returns (uint256) {
        return MAX_SUPPLY - totalSupply();
    }
}
