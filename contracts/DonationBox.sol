//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {FundBase} from './FundBase.sol';
import "./FundErrors.sol"; 

/// @title DonationBox - Tip jar for giving ETH donations to owner
/// @notice Anyone can donate ETH, only owner can withdraw
contract DonationBox is FundBase{
    constructor() FundBase(){}

    /// @notice Accepts ETH donations from anyone
    function depositFunds() external payable {
        if (msg.value <= 0) revert ZeroValueNotAllowed();
        emit Deposit(msg.sender, msg.value);
    }

    /// @notice Allows owner to withdraw a specific amount
    /// @param amount Amount of ETH to withdraw
    function withdrawFunds(uint256 amount) public onlyOwner nonReentrant returns (bool){
        if (!sendEth(amount, owner)) revert WithdrawalFailed();
        emit Withdrawal(msg.sender, amount);
        return true;
    }

    /// @notice Allows owner to withdraw full contract balance
    function withdrawAllFunds() external returns (bool){
        return withdrawFunds(address(this).balance);
    }
}
