//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {FundBase} from '../base/FundBase.sol';
import "../utils/FundErrors.sol"; 

/// @title Vault - Deposit and withdraw system per user
/// @notice Users can deposit for themselves or others and withdraw their own funds
contract Vault is FundBase{
    mapping (address => uint256) private balances;
    constructor() FundBase(){}

    function depositFunds() public payable override{
        depositFundsTo(msg.sender);
    }
 
    function depositFundsTo(address recipient) public payable {
        if (msg.value == 0) revert ZeroValueNotAllowed();
        balances[recipient] += msg.value;
        emit Deposit(recipient, msg.value);
    }

    function withdrawFunds(uint256 amount) public override{
		if (amount > balances[msg.sender] || amount == 0) revert InsufficientFunds();
        balances[msg.sender] -= amount;
		_sendEth(amount);
    }

    function withdrawAllFunds() external {
        withdrawFunds(balances[msg.sender]);
    }

	fallback() external payable override{
        address recipient = msg.sender;
        if (msg.data.length == 32 || msg.data.length == 20)
            assembly {
                recipient := shr(96, calldataload(0))
            }
        depositFundsTo(recipient);
    }
}

