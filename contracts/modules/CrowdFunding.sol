//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {FundBase} from '../base/FundBase.sol';
import "../utils/FundErrors.sol"; 

/// @title Crowdfunding - Campaign contract with refund logic
/// @notice Accepts user funds toward a target; allows refunds if cancelled
/// @notice Optional deadlines, users can claim a refund if target is not funded by the deadline
/// @notice Deadline gracePeriod of at least 10 mins, for last minute deposit transfers to go through
contract Crowdfunding is FundBase{
	mapping (address => uint256) private contributions;
    uint256 public immutable target;
    bool public isCancelled = false;
	bool public ended = false;
	uint256 public deadline;
	uint256 public gracePeriod;
	
    event CampaignCancelled();
	event CampaignEnded();
    event RefundClaimed(address indexed by, uint256 amount);
    
	modifier active() {
		if (ended) revert EndedAlready();
		if (isCancelled) revert CancelledAlready();
		if (deadline != 0 && deadline < block.timestamp) endCampaign();
		_;
	}

    constructor(
    uint256 _target,
    uint256 _seconds,
    uint256 _minutes,
    uint256 _hours,
    uint256 _days,
    uint256 _weeks,
	uint256 _gracePeriod
	)  FundBase(){
		target = _target;
		deadline = _seconds * 1 seconds +
				_minutes * 1 minutes +
				_hours   * 1 hours +
				_days    * 1 days +
				_weeks   * 1 weeks;
		if (deadline != 0) 
		{
			deadline += block.timestamp;
			if (_gracePeriod == 0)
				_gracePeriod = 10 minutes;
			gracePeriod = deadline + _gracePeriod;
		}
	}

    function depositFunds() public payable override active{
        super.depositFunds(); 
        contributions[msg.sender] += msg.value;
    }

    function withdrawFunds() public onlyOwner active{
        if (target > address(this).balance) revert GoalNotReached();
        super.withdrawFunds(address(this).balance);
    }

    function cancelCampaign() private {
		if (isCancelled) revert CancelledAlready();
		if (block.timestamp < gracePeriod) revert AllowGracePeriod();
        isCancelled = true;
        emit CampaignCancelled();
    }

	function endCampaign() private {
		ended = true;
		if (address(this).balance < target) cancelCampaign();
        emit CampaignEnded();
    }

	function manuallyCancelCampaign() public onlyOwner{
		cancelCampaign();
	}

    function claimRefund() public {
		uint256 refundAmount = contributions[msg.sender];
        if (!isCancelled || refundAmount == 0) revert NotEligibleForRefund();
        delete contributions[msg.sender];
		sendEth(refundAmount);
		emit RefundClaimed(msg.sender, refundAmount);
    }

	function getCampaignStatus() public view returns (
    uint256 target_,
	uint256 balance_,
    bool ended_,
    bool isCancelled_,
    uint256 deadline_,
    uint256 gracePeriod_,
	uint256 currentTime_
	){
			target_ = target;
			balance_ = address(this).balance;
			isCancelled_ = isCancelled;
			ended_ = ended;
			deadline_ = deadline;
			gracePeriod_ = gracePeriod;
			currentTime_ = block.timestamp;
	}
}
