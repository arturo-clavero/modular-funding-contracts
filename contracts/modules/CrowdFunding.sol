//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {FundBase} from '../base/FundBase.sol';
import "../utils/FundErrors.sol"; 

/// @title Crowdfunding - Campaign contract with refund logic
/// @notice Accepts user funds toward a target; allows refunds if cancelled
contract Crowdfunding is FundBase{
    uint256 immutable target;
    bool isCancelled = false;

    // Track each user's contribution
    mapping (address => uint256) private funds;

    event CampaignCancelled();
    event RefundClaimed(address indexed by, uint256 amount);
    
    /// @param _target Funding goal in wei
    constructor(uint256 _target) FundBase(){
        target = _target;
    }

    /// @notice Allows users to contribute to the campaign
    function depositFunds() public payable{  
        if (msg.value <= 0) revert ZeroValueNotAllowed();   
        funds[msg.sender] += msg.value;
        emit Deposit(msg.sender, msg.value);
    }

    fallback() external payable{
        depositFunds();
    }

    receive() external payable{
        depositFunds();
    }

    /// @notice Allows owner to withdraw all funds if target reached and not cancelled
    function withdrawFunds() public onlyOwner nonReentrant{
        if (isCancelled) revert CancelledAlready();
        if (target > address(this).balance) revert GoalNotReached();
        sendEth(address(this).balance, owner);
        emit Withdrawal(owner, address(this).balance);
    }

    /// @notice Owner can cancel the campaign (enables refunds)
    function cancel() public onlyOwner {
        isCancelled = true;
        emit CampaignCancelled();
    }

    /// @notice Contributors can claim a refund if campaign was cancelled
    function claimRefund()public nonReentrant{
        if (!isCancelled || funds[msg.sender] <= 0) revert NotEligibleForRefund();
        if (!sendEth(funds[msg.sender], msg.sender)) revert RefundFailed();
        emit RefundClaimed(msg.sender, funds[msg.sender]);
        delete funds[msg.sender];
    }
}
