// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {FundBase} from '../base/FundBase.sol';
import {AutomationCompatibleInterface} from "@chainlink/contracts/src/v0.8/automation/AutomationCompatible.sol";
import "../utils/FundErrors.sol"; 

/// @title Crowdfunding Campaign Contract with Refunds and Optional Whitelist
/// @notice Accepts user funds toward a funding target; supports refunds if campaign is cancelled
/// @notice Supports optional funding deadline and grace period for final deposits
contract CrowdFunding is FundBase, AutomationCompatibleInterface {
	/// @notice Tracks user contributions in wei
	mapping (address => uint256) private contributions;

	/// @notice Funding target amount in wei (immutable)
	uint256 public immutable target;

	/// @notice Timestamp when funding deadline expires (0 if no deadline)
	uint256 public deadline;

	/// @notice Timestamp until which grace period deposits are accepted
	uint256 public gracePeriod;

	/// @notice Flag indicating whether the campaign has been cancelled
	bool public isCancelled;

	/// @notice Flag indicating whether the campaign has ended
	bool public ended;

	/// @notice Flag indicating whether whitelist is active
	bool public isWhiteListed;

	/// @notice Mapping of whitelisted addresses
	mapping(address => bool) public whiteList;

	/// @notice Emitted when the campaign is cancelled by owner or deadline failure
	event CampaignCancelled();

	/// @notice Emitted when the campaign ends (successfully or cancelled)
	event CampaignEnded();

	/// @notice Emitted when a contributor claims a refund
	/// @param by The contributor claiming the refund
	/// @param amount The amount refunded in wei
	event RefundClaimed(address indexed by, uint256 amount);

	/// @notice Modifier to allow only active campaigns
	/// @dev Ends the campaign automatically if deadline passed
	modifier active() {
		if (ended) revert EndedAlready();
		if (isCancelled) revert CancelledAlready();
		if (deadline != 0 && deadline < block.timestamp) endCampaign();
		_;
	}

	/// @notice Modifier to enforce whitelist if enabled
	modifier whiteListAllowance() {
		if (!isWhiteListed) return;
		if (whiteList[msg.sender] == false) revert NotAuthorized();
		_;
	}

	/// @notice Constructor initializes campaign parameters and metadata
	/// @param _target Funding target in wei
	/// @param _seconds Seconds to add to deadline duration
	/// @param _minutes Minutes to add to deadline duration
	/// @param _hours Hours to add to deadline duration
	/// @param _days Days to add to deadline duration
	/// @param _weeks Weeks to add to deadline duration
	/// @param _gracePeriod Extra time after deadline for last-minute deposits (seconds)
	/// @param _whiteList Initial whitelist addresses (optional)
	/// @param name Campaign name
	/// @param description Campaign description
	/// @param imageUri URI of campaign image
	constructor(
		uint256 _target,
		uint256 _seconds,
		uint256 _minutes,
		uint256 _hours,
		uint256 _days,
		uint256 _weeks,
		uint256 _gracePeriod,
		address[] memory _whiteList,
		string memory name, 
		string memory description,
		string memory imageUri
	) FundBase(name, description, imageUri) {
		target = _target;
		deadline = _seconds * 1 seconds +
				_minutes * 1 minutes +
				_hours   * 1 hours +
				_days    * 1 days +
				_weeks   * 1 weeks;
		if (deadline != 0) {
			deadline += block.timestamp;
			if (_gracePeriod == 0)
				_gracePeriod = 10 minutes;
			gracePeriod = deadline + _gracePeriod;
		}
		addWhiteList(_whiteList);
	}

	/// @notice Chainlink Automation checkUpkeep method for deadline-based upkeep
	/// @dev Returns true if campaign deadline has passed and upkeep needed
	/// @param checkData Unused calldata input
	/// @return upkeepNeeded True if upkeep is needed
	/// @return performData Empty bytes, no data passed to performUpkeep
	function checkUpkeep(bytes calldata checkData) external view override returns (bool upkeepNeeded, bytes memory performData) {
		upkeepNeeded = deadline != 0 && deadline < block.timestamp;
		performData = "";
	}

	/// @notice Chainlink Automation performUpkeep method to end the campaign if deadline passed
	/// @param performData Unused bytes input
	function performUpkeep(bytes calldata performData) external override {
		endCampaign();
	}

	/// @notice Adds addresses to the whitelist, enabling whitelist mode if not already enabled
	/// @dev Only callable by the owner
	/// @param _whiteList Array of addresses to add to whitelist
	function addWhiteList(address[] memory _whiteList) public onlyOwner {
		if (_whiteList.length == 0) return;
		if (!isWhiteListed) isWhiteListed = true;
		for (uint256 i = 0; i < _whiteList.length; i++) {
			whiteList[_whiteList[i]] = true;
		}
	}

	/// @notice Removes an address from the whitelist
	/// @dev Only callable by the owner
	/// @param blackList Address to remove from whitelist
	function removeWhiteListFounder(address blackList) external onlyOwner {
		delete whiteList[blackList];
	}

	/// @notice Disables the whitelist mode (allows anyone to contribute)
	/// @dev Only callable by the owner
	function disableWhiteList() external onlyOwner {
		isWhiteListed = false;
	}

	/// @notice Enables the whitelist mode (restricts contributions to whitelisted addresses)
	/// @dev Only callable by the owner
	function enableWhiteList() external onlyOwner {
		isWhiteListed = true;
	}

	/// @notice Allows users to deposit funds if campaign is active and whitelist allows
	/// @dev Overrides FundBase.depositFunds to track individual contributions
	function depositFunds() public payable override active whiteListAllowance {
		super.depositFunds(); 
		contributions[msg.sender] += msg.value;
	}

	/// @notice Allows the owner to withdraw funds if campaign target is reached and active
	function withdrawFunds() public onlyOwner active {
		if (target > address(this).balance) revert GoalNotReached();
		super.withdrawFunds(address(this).balance);
	}

	/// @dev Internal function to cancel campaign, setting cancelled flag and emitting event
	function cancelCampaign() private {
		if (isCancelled) revert CancelledAlready();
		if (block.timestamp < gracePeriod) revert AllowGracePeriod();
		isCancelled = true;
		emit CampaignCancelled();
	}

	/// @dev Internal function to mark campaign as ended, and cancel if goal not reached
	function endCampaign() private {
		ended = true;
		if (address(this).balance < target) cancelCampaign();
		emit CampaignEnded();
	}

	/// @notice Allows owner to manually cancel the campaign after grace period
	function manuallyCancelCampaign() external onlyOwner {
		cancelCampaign();
	}

	/// @notice Allows contributors to claim refunds if campaign is cancelled
	/// @dev Refund amount is user’s contributed amount and contributions mapping cleared
	function claimRefund() external {
		uint256 refundAmount = contributions[msg.sender];
		if (!isCancelled || refundAmount == 0) revert NotEligibleForRefund();
		delete contributions[msg.sender];
		_sendEth(refundAmount);
		emit RefundClaimed(msg.sender, refundAmount);
	}

	/// @notice Returns current campaign status details
	/// @return target_ Funding target in wei
	/// @return balance_ Current contract balance in wei
	/// @return ended_ Whether campaign has ended
	/// @return isCancelled_ Whether campaign was cancelled
	/// @return deadline_ Timestamp of funding deadline
	/// @return gracePeriod_ Timestamp of grace period end
	/// @return currentTime_ Current block timestamp
	function getCampaignStatus() external view returns (
		uint256 target_,
		uint256 balance_,
		bool ended_,
		bool isCancelled_,
		uint256 deadline_,
		uint256 gracePeriod_,
		uint256 currentTime_
	) {
		target_ = target;
		balance_ = address(this).balance;
		isCancelled_ = isCancelled;
		ended_ = ended;
		deadline_ = deadline;
		gracePeriod_ = gracePeriod;
		currentTime_ = block.timestamp;
	}
}
