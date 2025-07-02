//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {FundBase} from './FundBase.sol';

/// @title Vault - Deposit and withdraw system per user
/// @notice Users can deposit for themselves or others and withdraw their own funds
contract Vault is FundBase{
    // Balance tracking for each user
    mapping (address => uint256) private funds;

    constructor() FundBase(){}

    /// @notice Deposit ETH to a specific user's balance
    /// @param recipient The user whose balance will be credited
    function depositFunds(address recipient) public payable{
        require(msg.value > 0, "Must send ETH");
        funds[recipient] += msg.value;
    }

    /// @notice Shortcut for topping up your own balance
    function topUp() public payable{
        depositFunds(msg.sender);
    }  

    /// @notice Withdraw a specific amount of your own funds
    /// @param amount Amount of ETH to withdraw  
    function withdrawFunds(uint256 amount) public returns (bool){
        require(amount > 0 && funds[msg.sender] >= amount, "Not enough funds");
        funds[msg.sender] -= amount;
        require(sendEth(amount, msg.sender), "");
        return true;
    }

    /// @notice Withdraw entire balance
    function withdrawAllFunds() external returns (bool){
        return withdrawFunds(funds[msg.sender]);
    }
}

