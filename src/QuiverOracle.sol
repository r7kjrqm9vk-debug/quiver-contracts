// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";

contract QuiverOracle is Ownable {

    struct PriceFeed {
        uint256 price;
        uint256 updatedAt;
        bool exists;
    }

    mapping(string => PriceFeed) public feeds;
    string[] public symbols;

    uint256 public constant IMBALANCE_THRESHOLD_BPS = 500;

    event PriceUpdated(string indexed symbol, uint256 price, uint256 timestamp);

    constructor() Ownable(msg.sender) {}

    function updatePrice(string calldata symbol, uint256 price) external onlyOwner {
        if (!feeds[symbol].exists) {
            symbols.push(symbol);
            feeds[symbol].exists = true;
        }
        feeds[symbol].price = price;
        feeds[symbol].updatedAt = block.timestamp;
        emit PriceUpdated(symbol, price, block.timestamp);
    }

    function updatePrices(string[] calldata _symbols, uint256[] calldata _prices) external onlyOwner {
        require(_symbols.length == _prices.length, "Length mismatch");
        for (uint256 i = 0; i < _symbols.length; i++) {
            if (!feeds[_symbols[i]].exists) {
                symbols.push(_symbols[i]);
                feeds[_symbols[i]].exists = true;
            }
            feeds[_symbols[i]].price = _prices[i];
            feeds[_symbols[i]].updatedAt = block.timestamp;
            emit PriceUpdated(_symbols[i], _prices[i], block.timestamp);
        }
    }

    function getPrice(string calldata symbol) external view returns (uint256) {
        require(feeds[symbol].exists, "Symbol not found");
        return feeds[symbol].price;
    }

    function getRatio(string calldata symbolA, string calldata symbolB) external view returns (uint256) {
        require(feeds[symbolA].exists && feeds[symbolB].exists, "Symbol not found");
        require(feeds[symbolB].price > 0, "Zero price");
        return (feeds[symbolA].price * 1e18) / feeds[symbolB].price;
    }

    function isImbalanced(uint256 poolRatio, string calldata symbolA, string calldata symbolB) external view returns (bool) {
        require(feeds[symbolA].exists && feeds[symbolB].exists, "Symbol not found");
        uint256 oracleRatio = (feeds[symbolA].price * 1e18) / feeds[symbolB].price;
        uint256 deviation;
        if (poolRatio > oracleRatio) {
            deviation = ((poolRatio - oracleRatio) * 10000) / oracleRatio;
        } else {
            deviation = ((oracleRatio - poolRatio) * 10000) / oracleRatio;
        }
        return deviation >= IMBALANCE_THRESHOLD_BPS;
    }

    function getAllSymbols() external view returns (string[] memory) {
        return symbols;
    }

    function isStale(string calldata symbol, uint256 maxAge) external view returns (bool) {
        return block.timestamp - feeds[symbol].updatedAt > maxAge;
    }
}
