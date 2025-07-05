//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {FundBase} from '../base/FundBase.sol';
import "../utils/FundErrors.sol"; 

/// @title Crowdfunding - Campaign contract with refund logic
/// @notice Accepts user funds toward a target; allows refunds if cancelled
contract Crowdfunding is FundBase{
    uint256 public immutable target;
    bool public isCancelled = false;
    mapping (address => uint256) private contributions;
    event CampaignCancelled();
    event RefundClaimed(address indexed by, uint256 amount);
    
    constructor(uint256 _target) FundBase(){
        target = _target;
    }

    function depositFunds() public payable override{
        super.depositFunds(); 
        contributions[msg.sender] += msg.value;
    }

    function withdrawFunds() public onlyOwner {
        if (isCancelled) revert CancelledAlready();
        if (target > address(this).balance) revert GoalNotReached();
        super.withdrawFunds(address(this).balance);
    }

    function cancelCampaign() public onlyOwner {
        isCancelled = true;
        emit CampaignCancelled();
    }

    function claimRefund() public {
		uint256 refundAmount = contributions[msg.sender];
        if (!isCancelled || refundAmount == 0) revert NotEligibleForRefund();
        delete contributions[msg.sender];
		sendEth(refundAmount);
		emit RefundClaimed();
    }
}
