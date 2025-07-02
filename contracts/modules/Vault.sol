//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {FundBase} from '../base/FundBase.sol';
import "../utils/FundErrors.sol"; 

/// @title Vault - Deposit and withdraw system per user
/// @notice Users can deposit for themselves or others and withdraw their own funds
contract Vault is FundBase{
    // Balance tracking for each user
    mapping (address => uint256) private funds;

    constructor() FundBase(){}

    /// @notice Deposit ETH to a specific user's balance
    /// @param recipient The user whose balance will be credited
    function depositFunds(address recipient) public payable {
        if (msg.value <= 0) revert ZeroValueNotAllowed();
        funds[recipient] += msg.value;
        emit Deposit(recipient, msg.value);
    }

    fallback() external payable{
        depositFunds(msg.sender);
    }
    
    receive() external payable{
        depositFunds(msg.sender);
    }

    /// @notice Shortcut for topping up your own balance
    function topUp() external payable{
        depositFunds(msg.sender);
    }  

    /// @notice Withdraw a specific amount of your own funds
    /// @param amount Amount of ETH to withdraw  
    function withdrawFunds(uint256 amount) public nonReentrant returns (bool){
        if (amount <= 0 || funds[msg.sender] <= amount) revert InsufficientFunds(amount, funds[msg.sender]);
        funds[msg.sender] -= amount;
        if (!sendEth(amount, msg.sender)) revert WithdrawalFailed();
        emit Withdrawal(msg.sender, amount);
        return true;
    }

    /// @notice Withdraw entire balance
    function withdrawAllFunds() external returns (bool){
        return withdrawFunds(funds[msg.sender]);
    }
}

