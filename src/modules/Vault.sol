// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {FundBase} from "../base/FundBase.sol";
import "../utils/FundErrors.sol";

/// @title Vault - Deposit and withdraw system per user
/// @notice Users can deposit funds for themselves or other recipients, and withdraw their own funds
contract Vault is FundBase {
    /// @notice Tracks balances per address
    mapping(address => uint256) private balances;

    /// @notice Constructs the Vault with metadata
    /// @param name The name of the vault
    /// @param description A description of the vault’s purpose
    constructor(string memory name, string memory description, address priceFeed)
        FundBase(name, description, priceFeed)
    {}

    /// @notice Deposit ETH for the caller’s own balance
    /// @dev Overrides base depositFunds to record per-user balance
    function depositFunds() public payable override {
        depositFundsTo(msg.sender);
    }

    function getMyBalance() public view returns (uint256) {
        return balances[msg.sender];
    }

    /// @notice Deposit ETH for a specified recipient’s balance
    /// @param recipient The address to credit with the deposit
    /// @dev Emits Deposit event on success; reverts if below minimum deposit
    function depositFundsTo(address recipient) public payable {
        if (msg.value < minDeposit || msg.value == 0) revert InsufficientDeposit();
        balances[recipient] += msg.value;
        emit Deposit(recipient, msg.value);
    }

    /// @notice Withdraw a specified amount of ETH from the caller’s balance
    /// @param amount Amount in wei to withdraw
    /// @dev Reverts if insufficient balance or zero amount
    function withdrawFunds(uint256 amount) public override {
        if (amount > balances[msg.sender] || amount == 0) revert InsufficientFunds();
        balances[msg.sender] -= amount;
        _sendEth(amount);
    }

    /// @notice Withdraws the caller’s entire balance
    function withdrawAllFunds() external {
        withdrawFunds(balances[msg.sender]);
    }

    /// @notice Fallback function to accept ETH deposits
    /// @dev Supports depositing for recipient specified by calldata (address encoded in first 20 or 32 bytes)
    fallback() external payable override {
        address recipient = msg.sender;
        if (msg.data.length == 32) {
            recipient = address(uint160(uint256(bytes32(msg.data))));
        } else if (msg.data.length == 20) {
            assembly {
                recipient := shr(0x60, calldataload(0))
            }
        }
        depositFundsTo(recipient);
    }
}
