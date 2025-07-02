//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "../utils/FundErrors.sol"; 

/// @title FundBase - Abstract base contract for fund logic
/// @notice Stores owner and provides internal ETH sending function
contract FundBase is ReentrancyGuard{
    address immutable owner;

    event Deposit(address indexed from, uint256 amount);
    event Withdrawal(address indexed to, uint256 amount);

    modifier onlyOwner(){
        if (msg.sender != owner) revert NotAuthorized();
        _;
    }

    /// @notice Sets the contract owner on deployment
    constructor() {
        owner = msg.sender;
    }

    /// @notice Internal helper to send ETH from the contract
    /// @param amount Amount of ETH to send
    /// @param recipient Address to receive the ETH
    /// @return success True if transfer succeeded
    function sendEth(uint256 amount, address recipient) internal returns (bool){
        if (address(this).balance < amount || amount <= 0) revert InsufficientFunds(amount, address(this).balance);
        (bool success, ) = payable(recipient).call{value: amount}("");
        if (!success) revert TransferFailed();
        return success;
    }
}


