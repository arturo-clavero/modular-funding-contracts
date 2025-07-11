// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "../utils/FundErrors.sol";
import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";
import {PriceConverter} from '../libs/PriceConverter.sol';
import {BlockRateLimiter} from '../libs/BlockRateLimiter.sol';

/// @title FundBase
/// @notice Abstract base contract for crowdfunding/funding logic
/// @dev Includes deposit/withdrawal, ETH transfer, metadata storage, and security (reentrancy + block rate limiting)
abstract contract FundBase is ReentrancyGuard, Ownable {

	/// @notice Campaign metadata struct
	struct MetaData {
		string name;
		string description;
		string imageUri;
	}

	/// @notice Metadata instance (immutable after deployment)
	MetaData public immutable metaData;

	/// @notice Minimum deposit amount required (in wei)
	uint256 public minDeposit;

	/// @dev Chainlink price converter config
	PriceConverter.ConverterData private priceRate;
	using PriceConverter for PriceConverter.ConverterData;

	/// @dev Withdrawal block limiter config (one per address)
	BlockRateLimiter.LimitData private blockRate;
	using BlockRateLimiter for BlockRateLimiter.LimitData;

	/// @notice Emitted when a user deposits ETH
	/// @param from The address sending the ETH
	/// @param amount The amount sent (in wei)
	event Deposit(address indexed from, uint256 amount);

	/// @notice Emitted when the owner withdraws ETH
	/// @param to The address receiving the ETH (owner)
	/// @param amount The amount withdrawn (in wei)
	event Withdrawal(address indexed to, uint256 amount);

	/// @notice Contract constructor to initialize metadata
	/// @param name Name of the fund/campaign
	/// @param description Description text
	/// @param imageUri Optional image URI for UI purposes
	constructor(
		string memory name,
		string memory description,
		string memory imageUri
	) {
		priceRate.initialize();
		metaData = MetaData(name, description, imageUri);
	}

	/// @notice Sets the minimum deposit (converted from fiat to ETH)
	/// @dev Uses Chainlink price feed via PriceConverter lib
	/// @param amount The fiat amount (e.g., 10 for $10)
	/// @param currency The fiat currency code (e.g., "USD")
	function setMinDeposit(uint256 amount, string calldata currency) public onlyOwner {
		minDeposit = priceRate.getRates(amount, currency);
	}

	/// @notice Sets a block-based withdrawal limit for the caller
	/// @param limit Number of blocks that must pass between withdrawals
	function setWithdrawalBlockLimit(uint256 limit) external {
		blockRate.setLimit(msg.sender, limit);
	}

	/// @notice Gets the current withdrawal block limit for the caller
	/// @return The block limit (in blocks)
	function getWithdrawalBlockLimit() external view returns (uint256) {
		return blockRate.getLimit(msg.sender);
	}

	/// @notice Withdraws ETH from the contract
	/// @dev Only callable by the owner, uses block rate limiting and reentrancy protection
	/// @param amount The amount to withdraw (in wei)
	function withdrawFunds(uint256 amount) public virtual onlyOwner {
		if (address(this).balance < amount || amount == 0) {
			revert InsufficientFunds(amount, address(this).balance);
		}
		blockRate.secureWithdrawal(msg.sender);
		_sendEth(amount);
		emit Withdrawal(msg.sender, amount);
	}

	/// @dev Internal helper to safely send ETH to caller
	/// @param amount The amount to send (in wei)
	function _sendEth(uint256 amount) internal nonReentrant {
		(bool success, ) = payable(msg.sender).call{value: amount}("");
		if (!success) revert TransferFailed();
	}

	/// @notice Deposit ETH into the contract
	/// @dev Requires value >= minDeposit. Emits `Deposit`.
	function depositFunds() public payable virtual {
		if (msg.value < minDeposit || msg.value == 0) {
			revert InsufficientDeposit();
		}
		emit Deposit(msg.sender, msg.value);
	}

	/// @notice Fallback function for receiving ETH with data
	fallback() external payable {
		depositFunds();
	}

	/// @notice Receive function for plain ETH transfers
	receive() external payable {
		depositFunds();
	}
}
