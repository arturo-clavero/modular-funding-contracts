# Modular ETH Funding System

This project is a set of modular Solidity smart contracts that enable different types of ETH funding workflows, including one-way donation boxes, user-specific vaults, and crowdfunding campaigns with refund logic. It includes on-chain metadata, Chainlink price feeds for fiat conversion, automated campaign handling via Chainlink Automation, and essential security features like reentrancy guards, ownership control, and withdrawal rate-limiting.

---

## Core Features

**FundBase** is the abstract base contract providing:

* On-chain metadata (name, description, image)
* Secure ETH transfer with reentrancy protection
* Owner-only withdrawals with rate-limiting by block number
* Minimum deposit enforcement using Chainlink price feeds (USD & EUR)
* Fallback and receive functions for ETH deposits
* Custom error definitions for efficient error handling

---

## Module Contracts

### DonationBox

Accepts ETH from anyone. Only the contract owner can withdraw.

### Vault

Users can deposit and withdraw their own ETH balances. Owner has no access.

### CrowdFunding

Campaign-based funding with optional deadline, refund logic, grace period enforcement, and optional whitelist. Automatically ends campaigns using Chainlink Automation.

---

## FundFactory

Deploys any of the above contracts and records their addresses. Emits a `FundContractCreated` event for each deployment.

---

## Security

* Uses `ReentrancyGuard` for all transfers
* Enforces `onlyOwner` access where appropriate
* Implements withdrawal rate-limiting to prevent rapid draining
* Grace period ensures fairness in campaign closures
* Optional whitelist to restrict contributions
* Chainlink price feeds validated before usage

---

## Tech Stack

| Technology      | Purpose                                     |
| --------------- | ------------------------------------------- |
| Solidity        | Core smart contract logic                   |
| OpenZeppelin    | Access control & security                   |
| Chainlink       | Fiat-to-ETH price conversion and automation |
| Remix           | Development, testing, and deployment        |

---

## License

MIT

---
