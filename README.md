# ☠ DeadDOT — On-Chain Dead Man's Switch

> _"Crypto inheritance in 100 lines. No lawyers. No seed phrases. Just a heartbeat."_

Built for the **Polkadot Solidity Hackathon 2026** — Track 2: PVM Smart Contracts.

---

## What is DeadDOT?

DeadDOT is a dead man's switch deployed on **Polkadot Hub**, compiled to **PVM bytecode via Revive (resolc)**.

- An owner sets a beneficiary and a ping interval
- The owner must **ping** the contract periodically to prove they're alive
- If the owner goes silent beyond the interval, the beneficiary can **claim all funds**
- The owner can cancel anytime and withdraw

Use cases: crypto inheritance, business continuity funds, time-locked grants, escrow with liveness guarantees.

---

## Why PVM?

DeadDOT is compiled with **resolc (Revive)** — Parity's Solidity → RISC-V compiler — targeting the Polkadot Virtual Machine directly:

- **Not EVM bytecode** — RISC-V binary running natively on PVM
- Native WND transfers — no wrapped tokens, no bridges
- Deployed via standard Ethereum tooling (ethers.js) — no Substrate calls needed

---

## Live Deployment

| Field    | Value                                          |
| -------- | ---------------------------------------------- |
| Network  | Polkadot Hub Testnet                           |
| Chain ID | `420420417`                                    |
| RPC      | `https://services.polkadothub-rpc.com/testnet` |
| Contract | `0x5f8496ACBb691933e2D55A81b9f2340712EE64f4`   |
| Compiler | resolc v0.1.0-dev.12 (Revive)                  |

---

## Contract

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract DeadDOT {
    address public owner;
    address public beneficiary;
    uint256 public interval;
    uint256 public lastPing;
    bool    public triggered;

    constructor(address _beneficiary, uint256 _interval) { ... }
    function ping() external          // owner resets countdown
    function withdraw() external      // owner cancels + reclaims
    function claim() external         // beneficiary claims after silence
    function timeRemaining() external view returns (uint256)
    receive() external payable
}
```

**Security:** CEI pattern, `triggered = true` set before transfers, minimum 1-hour interval enforced.

DeadDOT sends and receives **WND** (Polkadot's native asset) directly — no ERC-20 wrapping, no bridges. `claim()` and `withdraw()` transfer native value on-chain via low-level `call{value}`.

---

## Demo Flow

1. Open `index.html`, connect MetaMask on Chain ID `420420417`
2. As **owner** — click **Ping** to reset the countdown
3. Switch to **beneficiary** wallet after interval expires
4. Click **Claim Inheritance** — funds transfer on-chain

---

## Setup

### 1. Install resolc (Revive compiler)

```bash
mkdir -p bin

# macOS (Apple Silicon)
curl -L https://github.com/paritytech/revive/releases/download/v0.1.0-dev.12/resolc-universal-apple-darwin \
  -o bin/resolc && xattr -c bin/resolc && chmod +x bin/resolc

# Linux
curl -L https://github.com/paritytech/revive/releases/download/v0.1.0-dev.12/resolc-x86_64-unknown-linux-musl \
  -o bin/resolc && chmod +x bin/resolc
```

### 2. Compile to PVM

```bash
./bin/resolc --bin DeadDOT.sol -o ./out
```

Output: `./out/DeadDOT.sol:DeadDOT.pvm`

### 3. Install dependencies

```bash
npm install
```

### 4. Configure `.env`

```
PRIVATE_KEY=0x...
BENEFICIARY_ADDRESS=0x...
```

### 5. Deploy

```bash
npm run deploy
```

### 6. Add network to MetaMask

| Field    | Value                                          |
| -------- | ---------------------------------------------- |
| RPC URL  | `https://services.polkadothub-rpc.com/testnet` |
| Chain ID | `420420417`                                    |
| Symbol   | `WND`                                          |

---

## Track Qualification

**Track 2: PVM Smart Contracts**
**Category: Accessing Polkadot native functionality — build with precompiles**

- ✅ Compiled to PVM via resolc (Revive) — not EVM bytecode
- ✅ Native WND transfers on Polkadot Hub
- ✅ Deployed on Polkadot Hub testnet Chain ID 420420417
- ✅ Standard Ethereum tooling — ethers.js, MetaMask

---

## Built With

- **Solidity ^0.8.20**
- **resolc v0.1.0-dev.12 (Revive)** — Solidity → RISC-V / PVM
- **ethers.js v6** — deployment + frontend
- **Remix Polkadot IDE** — used for final deployment
- Vanilla HTML/CSS/JS frontend — zero framework dependencies

---

## License

MIT