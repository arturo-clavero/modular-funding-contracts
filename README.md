# Modular Funding Contracts

A set of reusable and composable Ethereum smart contracts for managing ETH-based funding mechanisms. Includes donation, vault, and crowdfunding logic, built around a shared base contract for secure ETH transfers and ownership access control.

## Features

### Core Logic

* Unified architecture using a base `FundBase` contract for consistent logic across all funding types
* ETH transfer operations encapsulated in a secure internal function with balance and success checks
* Explicit custom errors for clearer and more gas-efficient failure handling
* Centralized access control via the `onlyOwner` modifier for administrative actions
* Integrated reentrancy protection using OpenZeppelin's `ReentrancyGuard`
* Standardized event logging to enable off-chain tracking and frontend integrationEvent logging for key actions such as deposits, withdrawals, and refunds

### Contract Types

* **DonationBox**: Accepts donations; only the owner can withdraw
* **Crowdfunding**: Goal-based funding; refunds available if canceled
* **Vault**: Users can deposit and withdraw their individual balances

## Features To Do

### Chainlink & Conversion Logic

* Add Chainlink Price Feed integration (ETH/USD and others)
* Enable fiat-based funding goals (auto-convert to ETH)
* Show ETH value in fiat using live oracle data

### Time-Based Logic

* Add funding deadlines to crowdfunding campaigns
* Implement auto-cancel or restrict deposits after deadline

### Advanced Fund Logic

* Add donation matching by owner
* Track top donor or largest contributors
* Simulate gas refund incentives for donors or failed campaigns

### Access Control

* Add whitelisted funders or withdrawers
* Implement role-based access using OpenZeppelin `AccessControl`

### ERC20 Token Support

* Allow deposits and withdrawals in ERC20 tokens (e.g. USDC, DAI)
* Create ERC20-compatible versions of `Vault`, `Crowdfunding`, etc.

### Oracle Redundancy

* Add fallback or multi-oracle pricing (combine Chainlink, Redstone, Uniswap)
* Use median-based or priority-based price selection

### Deployment & Metadata

* Build a FundFactory contract to deploy fund instances
* Add metadata support (name, description, goal summary) for frontend display
* Optimize contract deployment using EIP-1167 (minimal proxy)
