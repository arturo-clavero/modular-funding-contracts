// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "../utils/FundErrors.sol";
// import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";
// import {PriceConverter} from '../libs/PriceConverter.sol';
// import {BlockRateLimiter} from '../libs/BlockRateLimiter.sol';

// abstract contract FundBase is ReentrancyGuard, Ownable {
contract FundBase is ReentrancyGuard, Ownable {
	// struct MetaData {
	// 	string name;
	// 	string description;
	// 	string imageUri;
	// }

	// MetaData public immutable metaData;

	// uint256 public minDeposit;

	// PriceConverter.ConverterData private priceRate;
	// using PriceConverter for PriceConverter.ConverterData;


	// BlockRateLimiter.LimitData private blockRate;
	// using BlockRateLimiter for BlockRateLimiter.LimitData;

	event Deposit(address indexed from, uint256 amount);
	event Withdrawal(address indexed to, uint256 amount);

	constructor(
		// string memory name,
		// string memory description,
		// string memory imageUri,
		address initialOwner
	)
	Ownable(initialOwner) {
		// priceRate.initialize();
		// metaData = MetaData(name, description, imageUri);
	}

	// function setMinDeposit(uint256 amount, string calldata currency) public onlyOwner {
	// 	minDeposit = priceRate.getRates(amount, currency);
	// }


	// function setWithdrawalBlockLimit(uint256 limit) external {
	// 	blockRate.setLimit(msg.sender, limit);
	// }


	// function getWithdrawalBlockLimit() external view returns (uint256) {
	// 	return blockRate.getLimit(msg.sender);
	// }


	function withdrawFunds(uint256 amount) public virtual onlyOwner {
		if (address(this).balance < amount || amount == 0) {
			revert InsufficientFunds(amount, address(this).balance);
		}
		// blockRate.secureWithdrawal(msg.sender);
		_sendEth(amount);
		emit Withdrawal(msg.sender, amount);
	}

	function _sendEth(uint256 amount) internal nonReentrant {
		(bool success, ) = payable(msg.sender).call{value: amount}("");
		if (!success) revert TransferFailed();
	}

	function depositFunds() public payable virtual {
		// if (msg.value < minDeposit || msg.value == 0) {
		if (msg.value == 0) {
			revert InsufficientDeposit();
		}
		emit Deposit(msg.sender, msg.value);
	}

	fallback() external payable {
		depositFunds();
	}

	receive() external payable {
		depositFunds();
	}
}
