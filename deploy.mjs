import { ethers } from "ethers";
import { readFileSync } from "fs";
import "dotenv/config";

const RPC         = "https://services.polkadothub-rpc.com/testnet";
const BENEFICIARY = process.env.BENEFICIARY_ADDRESS;
const INTERVAL    = 3600; // 1 hour for demo (use 2592000 for 30 days in prod)
const PRIVATE_KEY = process.env.PRIVATE_KEY;

const bytecode = "0x" + readFileSync("./out/DeadDOT.sol:DeadDOT.pvm").toString("hex");

const ABI = ["constructor(address _beneficiary, uint256 _interval)"];

const provider = new ethers.JsonRpcProvider(RPC);
const wallet   = new ethers.Wallet(PRIVATE_KEY, provider);
const factory  = new ethers.ContractFactory(ABI, bytecode, wallet);

console.log("Deploying DeadDOT...");
console.log("Deployer:", wallet.address);

if (!BENEFICIARY) throw new Error("BENEFICIARY_ADDRESS not set in .env");

const contract = await factory.deploy(BENEFICIARY, INTERVAL);

console.log("Tx hash:", contract.deploymentTransaction()?.hash);
console.log("Waiting for confirmation...");

await contract.waitForDeployment();

const address = await contract.getAddress();
console.log("✓ DeadDOT deployed at:", address);
console.log(`\nUpdate index.html:\nconst CONTRACT_ADDRESS = "${address}";`);
