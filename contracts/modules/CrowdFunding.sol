//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {FundBase} from '../base/FundBase.sol';
import "../utils/FundErrors.sol"; 

/// @title Crowdfunding - Campaign contract with refund logic
/// @notice Accepts user funds toward a target; allows refunds if cancelled
/// @notice Optional deadlines, users can claim a refund if target is not funded by the deadline
contract Crowdfunding is FundBase{
	mapping (address => uint256) private contributions;
    uint256 public immutable target;
    bool public isCancelled = false;
	bool public ended = false;
	uint256 public deadline;
	
    event CampaignCancelled();
	event CampaignEnded();
    event RefundClaimed(address indexed by, uint256 amount);
    
	modifier stillActive() {
		if (isCancelled) revert CancelledAlready();
		if (ended) revert EndedAlready();
		if (deadline != 0 && deadline < block.timestamp) endCampaign();
		_;
	}

    constructor(
    uint256 _target,
    uint256 _seconds,
    uint256 _minutes,
    uint256 _hours,
    uint256 _days,
    uint256 _weeks
	)  FundBase(){
		target = _target;
		deadline = _seconds * 1 seconds +
				_minutes * 1 minutes +
				_hours   * 1 hours +
				_days    * 1 days +
				_weeks   * 1 weeks;
		if (deadline != 0) deadline += block.timestamp;
	}

    function depositFunds() public payable override stillActive{
        super.depositFunds(); 
        contributions[msg.sender] += msg.value;
    }

    function withdrawFunds() public onlyOwner stillActive{
        if (target > address(this).balance) revert GoalNotReached();
        super.withdrawFunds(address(this).balance);
    }

    function cancelCampaign() public onlyOwner {
		if (isCancelled) revert CancelledAlready();
        isCancelled = true;
        emit CampaignCancelled();
    }

	function endCampaign() private {
		ended = true;
		if (address(this).balance < target) cancelCampaign();
        emit CampaignEnded();
    }

    function claimRefund() public {
		uint256 refundAmount = contributions[msg.sender];
        if (!isCancelled || refundAmount == 0) revert NotEligibleForRefund();
        delete contributions[msg.sender];
		sendEth(refundAmount);
		emit RefundClaimed();
    }
}
