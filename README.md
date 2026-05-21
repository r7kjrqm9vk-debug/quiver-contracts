# Quiver Protocol 🏹

**The first stock-to-stock AMM on Robinhood Chain.**

Swap tokenized equities directly against each other — no USD, no stablecoins. Oracle-anchored to real market prices via Finnhub, with auto-rebalance and native $QVR burn economics.

## Live on Robinhood Chain Testnet

🌐 [quiver-protocol.vercel.app](https://quiver-protocol.vercel.app)

## Contracts (Chain ID: 46630)

| Contract | Address |
|---|---|
| QuiverToken ($QVR) | `0xd8690c73988C593033De284A0eEeD6bCf5C1ef25` |
| QuiverFaucet | `0x67663805e59A497196CF99119934e0352Ae360d4` |
| QuiverOracle | `0xF2b1DcB76C26ec79EB240CDBb3E0a2E0c3403A3a` |
| QuiverFactory | `0x68c89b8d5B860A08a884d1A0C833Baf8F241c8F1` |
| Pool AMD/TSLA | `0x0227d1e5d5AFb93A96192dB9717a80DB77D2D5E2` |
| Pool AMZN/TSLA | `0x6C2fC2923f225A207F26E380cda1eceC09d4FFE7` |
| Pool NFLX/AMZN | `0x8A7564CB7638767dfEB703C9050f19E1C398c325` |
| Pool PLTR/AMD | `0x6879852c5DA24993e76d8C69A4ADa942Cb76Eb89` |
| Pool NFLX/TSLA | `0x5f8021925EB18B9243f8616A4547492e6c993bA2` |

## Architecture

QuiverToken ($QVR) — ERC20, 1M max supply, burn economics QuiverFaucet — 100 QVR / 24h per wallet, tracks unique users QuiverOracle — Fed by Finnhub API every 5 min via keeper QuiverFactory — Deploys pools, manages keeper rewards QuiverPool — x*y=k AMM with oracle rebalance mechanism

## How It Works

1. **Swap** stock tokens directly — TSLA→AMD, NFLX→AMZN etc.
2. **Oracle** keeps pool ratios anchored to real market prices
3. **Rebalance** — any wallet calls `rebalance()` on drifted pools and earns $QVR
4. **Fees** — 0.3% in tokenIn: 0.15% burned, 0.15% stays in pool
5. **$QVR** — burn 1 QVR per swap, 5 per addLiquidity, 10 per createPool

## Setup

```bash
git clone https://github.com/r7kjrqm9vk-debug/quiver-protocol
cd quiver-protocol
forge install
forge build
```

## Deploy

```bash
cp .env.example .env
# Add PRIVATE_KEY to .env

forge script script/DeployToken.s.sol:DeployToken \
  --rpc-url https://rpc.testnet.chain.robinhood.com/rpc \
  --broadcast --private-key $PRIVATE_KEY
```

## Keeper

```bash
cd keeper
npm install
# Add PRIVATE_KEY and FINNHUB_API_KEY to .env
node keeper.js
```

## Contributing

Quiver started as an experiment. Forks, PRs, and feedback welcome.

## License

MIT

## Dependencies

```bash
forge install OpenZeppelin/openzeppelin-contracts
forge install foundry-rs/forge-std
```
