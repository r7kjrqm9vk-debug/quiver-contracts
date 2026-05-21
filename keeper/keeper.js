import { ethers } from "ethers";
import fetch from "node-fetch";
import dotenv from "dotenv";
dotenv.config({ path: "../.env" });

// Config
const RPC_URL = "https://rpc.testnet.chain.robinhood.com/rpc";
const FINNHUB_KEY = process.env.FINNHUB_API_KEY;
const PRIVATE_KEY = process.env.PRIVATE_KEY;
const INTERVAL_MS = 5 * 60 * 1000; // 5 minuti

// Indirizzi
const ORACLE_ADDRESS  = "0xF2b1DcB76C26ec79EB240CDBb3E0a2E0c3403A3a";
const FACTORY_ADDRESS = "0x68c89b8d5B860A08a884d1A0C833Baf8F241c8F1";

const POOLS = [
  { address: "0x0227d1e5d5AFb93A96192dB9717a80DB77D2D5E2", name: "AMD/TSLA" },
  { address: "0x6C2fC2923f225A207F26E380cda1eceC09d4FFE7", name: "AMZN/TSLA" },
  { address: "0x8A7564CB7638767dfEB703C9050f19E1C398c325", name: "NFLX/AMZN" },
  { address: "0x6879852c5DA24993e76d8C69A4ADa942Cb76Eb89", name: "PLTR/AMD" },
  { address: "0x5f8021925EB18B9243f8616A4547492e6c993bA2", name: "NFLX/TSLA" },
];

const SYMBOLS = ["TSLA", "AMD", "AMZN", "NFLX", "PLTR"];

// ABIs minimi
const ORACLE_ABI = [
  "function updatePrices(string[] calldata symbols, uint256[] calldata prices) external",
  "function isImbalanced(uint256 poolRatio, string calldata symbolA, string calldata symbolB) external view returns (bool)",
];

const POOL_ABI = [
  "function rebalance() external",
  "function isImbalanced() external view returns (bool)",
  "function symbolA() external view returns (string)",
  "function symbolB() external view returns (string)",
  "function reserveA() external view returns (uint256)",
  "function reserveB() external view returns (uint256)",
];

// Setup provider e contratti
const provider = new ethers.JsonRpcProvider(RPC_URL);
const wallet = new ethers.Wallet(PRIVATE_KEY, provider);
const oracle = new ethers.Contract(ORACLE_ADDRESS, ORACLE_ABI, wallet);

// Fetch prezzi da Finnhub
async function fetchPrices() {
  const prices = {};
  for (const symbol of SYMBOLS) {
    try {
      const url = `https://finnhub.io/api/v1/quote?symbol=${symbol}&token=${FINNHUB_KEY}`;
      const res = await fetch(url);
      const data = await res.json();
      if (data.c && data.c > 0) {
        // Converti in 8 decimali come Chainlink
        prices[symbol] = BigInt(Math.round(data.c * 1e8));
        console.log(`  ${symbol}: $${data.c}`);
      } else {
        console.warn(`  ${symbol}: no data`);
      }
    } catch (e) {
      console.error(`  ${symbol} fetch error:`, e.message);
    }
  }
  return prices;
}

// Aggiorna oracle on-chain
async function updateOracle(prices) {
  const symbols = Object.keys(prices);
  const values = symbols.map(s => prices[s]);

  if (symbols.length === 0) {
    console.log("No prices to update");
    return;
  }

  try {
    const tx = await oracle.updatePrices(symbols, values);
    await tx.wait();
    console.log(`  Oracle updated: ${tx.hash}`);
  } catch (e) {
    console.error("  Oracle update failed:", e.message);
  }
}

// Controlla e rebalancia le pool sbilanciate
async function checkAndRebalance() {
  for (const pool of POOLS) {
    try {
      const contract = new ethers.Contract(pool.address, POOL_ABI, wallet);
      const imbalanced = await contract.isImbalanced();

      if (imbalanced) {
        console.log(`  🔄 ${pool.name} is imbalanced — rebalancing...`);
        const tx = await contract.rebalance();
        await tx.wait();
        console.log(`  ✅ ${pool.name} rebalanced: ${tx.hash}`);
      } else {
        console.log(`  ✅ ${pool.name} balanced`);
      }
    } catch (e) {
      console.error(`  ${pool.name} rebalance error:`, e.message);
    }
  }
}

// Loop principale
async function run() {
  console.log("🏹 Quiver Keeper started");
  console.log(`   Interval: ${INTERVAL_MS / 1000}s`);
  console.log(`   Oracle: ${ORACLE_ADDRESS}`);
  console.log(`   Wallet: ${wallet.address}\n`);

  while (true) {
    const now = new Date().toISOString();
    console.log(`\n[${now}] Running keeper cycle...`);

    try {
      // 1. Fetch prezzi
      console.log("📡 Fetching prices from Finnhub...");
      const prices = await fetchPrices();

      // 2. Aggiorna oracle
      console.log("📝 Updating oracle...");
      await updateOracle(prices);

      // 3. Controlla pool
      console.log("🔍 Checking pools...");
      await checkAndRebalance();

    } catch (e) {
      console.error("Cycle error:", e.message);
    }

    console.log(`\n⏳ Next cycle in ${INTERVAL_MS / 1000}s...`);
    await new Promise(r => setTimeout(r, INTERVAL_MS));
  }
}

run();
