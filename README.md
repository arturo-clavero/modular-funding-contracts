# Modular Funding Contracts
A modular, gas-efficient funding system on Ethereum, featuring donation, crowdfunding, and vault logic with Chainlink price feeds, access control, and scalable deployment.
A set of reusable and composable Ethereum smart contracts for managing ETH-based funding mechanisms. Includes donation, vault, and crowdfunding logic, built around a shared base contract for secure ETH transfers and ownership access control.

## Features

### Core Logic

* Unified architecture using a base `FundBase` contract for consistent logic across all funding types
* ETH transfer operations encapsulated in a secure internal function with balance and success checks
* Explicit custom errors for clearer and more gas-efficient failure handling
* Centralized access control via the `onlyOwner` modifier for administrative actions
* Integrated reentrancy protection using OpenZeppelin's `ReentrancyGuard`
* Standardized event logging to enable off-chain tracking and frontend integrationEvent logging for key actions such as deposits, withdrawals, and refunds
* Withdrawal block until limit.
* Whitelisted deposit allowance.
* Meta Data.
* FundFactory 


### Contract Types

* **DonationBox**: Accepts donations; only the owner can withdraw
* **Crowdfunding**: Goal-based funding; refunds available if canceled; deadlines and grace periods;
* **Vault**: Users can deposit and withdraw their individual balances

## Features To Do Now
Chainlink ETH/USD + fiat goal logic	

## Features To Do Later
ERC20 support 
EIP-1167 (minimal proxy)