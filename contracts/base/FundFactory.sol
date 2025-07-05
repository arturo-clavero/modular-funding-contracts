//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {DonationBox} from '../modules/DonationBox.sol';
import {Vault} from '../modules/Vault.sol';
import {CrowdFunding} from '../modules/CrowdFunding.sol';

contract FundFactory{
	address[] public deployedFundContracts;

	event FundContractCreated(address indexed newContract, address indexed owner);

	function registerContract(address newFundContract) internal{
		deployedFundContracts.push(newFundContract);
		emit FundContractCreated(newFundContract, msg.sender);
	}
	function createDonationBox(
		string memory name,
		string memory description, 
		string memory imageUri
	) external {
		DonationBox newFundContract = new DonationBox(
			name,
			description, 
			imageUri
		);
		registerContract(address(newFundContract));
	}

	function createVault(
		string memory name,
		string memory description, 
		string memory imageUri
	) external {
		Vault newFundContract = new Vault(
			name, 
			description,
			imageUri
		);
		registerContract(address(newFundContract));
	}

	function createCrowFundingContract(
		uint256 _target,
		uint256 _seconds,
		uint256 _minutes,
		uint256 _hours,
		uint256 _days,
		uint256 _weeks,
		uint256 _gracePeriod,
		address[] _whiteList,
		string memory name, 
		string memory description,
		string memory imageUri
	) external{
		CrowdFunding newFundContract = new CrowdFunding(
			_target, 
			_seconds, 
			_minutes, 
			_hours, 
			_days, 
			_weeks, 
			_gracePeriod, 
			_whiteList, 
			name, 
			description, 
			imageUri
		);
		registerContract(address(newFundContract));
	}

}