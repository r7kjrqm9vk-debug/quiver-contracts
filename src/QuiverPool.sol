// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "./QuiverToken.sol";
import "./QuiverOracle.sol";
import "./QuiverFactory.sol";

contract QuiverPool is ERC20, ReentrancyGuard {
    IERC20 public immutable tokenA;
    IERC20 public immutable tokenB;
    string public symbolA;
    string public symbolB;

    QuiverToken public immutable qvr;
    QuiverOracle public immutable oracle;
    QuiverFactory public immutable factory;

    uint256 public reserveA;
    uint256 public reserveB;

    // Fee: 0.3% = 30 bps
    // Split: 0.15% burn + 0.15% resta nella pool
    uint256 public constant FEE_BPS = 30;
    uint256 public constant BURN_BPS = 15;

    // QVR costs
    uint256 public constant SWAP_COST = 1 * 1e18;
    uint256 public constant LIQUIDITY_COST = 5 * 1e18;
    uint256 public constant REBALANCE_REWARD_SHARE = 10 * 1e18;

    event LiquidityAdded(address indexed provider, uint256 amountA, uint256 amountB, uint256 shares);
    event LiquidityRemoved(address indexed provider, uint256 amountA, uint256 amountB, uint256 shares);
    event Swap(address indexed user, address tokenIn, uint256 amountIn, uint256 amountOut);
    event Rebalanced(address indexed keeper, uint256 newReserveA, uint256 newReserveB);

    constructor(
        address _tokenA,
        address _tokenB,
        string memory _symbolA,
        string memory _symbolB,
        address _qvr,
        address _oracle,
        address _factory
    ) ERC20("Quiver-LP", "QLP") {
        tokenA = IERC20(_tokenA);
        tokenB = IERC20(_tokenB);
        symbolA = _symbolA;
        symbolB = _symbolB;
        qvr = QuiverToken(_qvr);
        oracle = QuiverOracle(_oracle);
        factory = QuiverFactory(_factory);
    }

    function addLiquidity(uint256 amountA, uint256 amountB)
        external nonReentrant returns (uint256 shares)
    {
        // Burn QVR cost
        _splitBurnQVR(msg.sender, LIQUIDITY_COST);

        tokenA.transferFrom(msg.sender, address(this), amountA);
        tokenB.transferFrom(msg.sender, address(this), amountB);

        if (totalSupply() == 0) {
            shares = _sqrt(amountA * amountB);
        } else {
            shares = _min(
                (amountA * totalSupply()) / reserveA,
                (amountB * totalSupply()) / reserveB
            );
        }

        require(shares > 0, "Zero shares");
        _mint(msg.sender, shares);

        reserveA += amountA;
        reserveB += amountB;

        emit LiquidityAdded(msg.sender, amountA, amountB, shares);
    }

    function swap(address tokenIn, uint256 amountIn)
        external nonReentrant returns (uint256 amountOut)
    {
        require(tokenIn == address(tokenA) || tokenIn == address(tokenB), "Invalid token");
        require(amountIn > 0, "Zero amount");

        // Burn QVR cost — split 50/50
        _splitBurnQVR(msg.sender, SWAP_COST);

        bool isA = tokenIn == address(tokenA);
        (IERC20 tIn, IERC20 tOut, uint256 resIn, uint256 resOut) = isA
            ? (tokenA, tokenB, reserveA, reserveB)
            : (tokenB, tokenA, reserveB, reserveA);

        tIn.transferFrom(msg.sender, address(this), amountIn);

        // Fee 0.3% sul tokenIn
        uint256 burnFee = (amountIn * BURN_BPS) / 10000;   // 0.15% bruciato
        uint256 poolFee = (amountIn * BURN_BPS) / 10000;   // 0.15% resta in pool

        // Burn fee in tokenIn — invia a dead address
        tIn.transfer(address(0x000000000000000000000000000000000000dEaD), burnFee);

        uint256 amountInEffective = amountIn - burnFee - poolFee;

        // x * y = k
        amountOut = (amountInEffective * resOut) / (resIn + amountInEffective);

        require(amountOut > 0, "Zero output");
        require(amountOut < resOut, "Insufficient liquidity");

        tOut.transfer(msg.sender, amountOut);

        // Aggiorna riserve
        if (isA) {
            reserveA = reserveA + amountIn - burnFee;
            reserveB = reserveB - amountOut;
        } else {
            reserveB = reserveB + amountIn - burnFee;
            reserveA = reserveA - amountOut;
        }

        emit Swap(msg.sender, tokenIn, amountIn, amountOut);
    }

    function removeLiquidity(uint256 shares)
        external nonReentrant returns (uint256 amountA, uint256 amountB)
    {
        require(shares > 0, "Zero shares");
        uint256 supply = totalSupply();

        amountA = (shares * reserveA) / supply;
        amountB = (shares * reserveB) / supply;

        require(amountA > 0 && amountB > 0, "Zero amounts");

        _burn(msg.sender, shares);
        reserveA -= amountA;
        reserveB -= amountB;

        tokenA.transfer(msg.sender, amountA);
        tokenB.transfer(msg.sender, amountB);

        emit LiquidityRemoved(msg.sender, amountA, amountB, shares);
    }

    /// @notice Chiunque può chiamare se pool è sbilanciata — riceve reward QVR
    function rebalance() external nonReentrant {
        uint256 currentRatio = (reserveB * 1e18) / reserveA;
        require(
            oracle.isImbalanced(currentRatio, symbolA, symbolB),
            "Pool balanced"
        );

        // Calcola nuovo ratio dall'oracle
        uint256 oracleRatio = oracle.getRatio(symbolA, symbolB);

        // Ribilancia le riserve mantenendo k costante
        // newReserveA * newReserveB = reserveA * reserveB = k
        // newReserveB = newReserveA * oracleRatio / 1e18
        // newReserveA^2 * oracleRatio / 1e18 = k
        uint256 k = reserveA * reserveB;
        uint256 newReserveA = _sqrt((k * 1e18) / oracleRatio);
        uint256 newReserveB = (newReserveA * oracleRatio) / 1e18;

        reserveA = newReserveA;
        reserveB = newReserveB;

        // Paga il keeper tramite Factory
        factory.payKeeper(address(this), msg.sender);

        emit Rebalanced(msg.sender, newReserveA, newReserveB);
    }

    function getPrice() external view returns (uint256 priceAinB, uint256 priceBinA) {
        require(reserveA > 0 && reserveB > 0, "No liquidity");
        priceAinB = (reserveB * 1e18) / reserveA;
        priceBinA = (reserveA * 1e18) / reserveB;
    }

    function getCurrentRatio() external view returns (uint256) {
        require(reserveA > 0 && reserveB > 0, "No liquidity");
        return (reserveB * 1e18) / reserveA;
    }

    function isImbalanced() external view returns (bool) {
        if (reserveA == 0 || reserveB == 0) return false;
        uint256 currentRatio = (reserveB * 1e18) / reserveA;
        return oracle.isImbalanced(currentRatio, symbolA, symbolB);
    }

    /// @notice Split burn QVR: 50% a 0xdead, 50% a Factory RewardPool
    function _splitBurnQVR(address from, uint256 amount) internal {
        uint256 half = amount / 2;
        uint256 otherHalf = amount - half;

        qvr.transferFrom(from, address(0x000000000000000000000000000000000000dEaD), half);
        qvr.transferFrom(from, address(factory), otherHalf);

        factory.addReward(address(this), otherHalf);
    }

    function _sqrt(uint256 y) internal pure returns (uint256 z) {
        if (y > 3) {
            z = y;
            uint256 x = y / 2 + 1;
            while (x < z) { z = x; x = (y / x + x) / 2; }
        } else if (y != 0) {
            z = 1;
        }
    }

    function _min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }
}
