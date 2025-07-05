//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "../utils/FundErrors.sol"; 
import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";

/// @title FundBase - Abstract base contract for fund logic
/// @notice Stores owner and provides internal ETH sending function
contract FundBase is ReentrancyGuard, Ownable{
	struct MetaData {
		string name;
		string description;
		string imageUri;
	}
	uint256 public minDeposit;
    AggregatorV3Interface internal feedUSDtoETH;
	AggregatorV3Interface internal feedEURtoETH;
	uint256 chainLinkDecimals = 10;
	MetaData public metaData;
	uint256 public constant standardBlockLimit = 3;
	mapping(address=>uint256) private previousWithdrawalBlock;
	mapping(address=>uint256) private withdrawalBlockLimit;


    event Deposit(address indexed from, uint256 amount);
    event Withdrawal(address indexed to, uint256 amount);

	modifier secureWithdrawal(){
		uint256 limit = withdrawalBlockLimit[msg.sender];
		if (limit == 0)
			limit = standardBlockLimit;
		if (block.number < previousWithdrawalBlock[msg.sender] + limit)
			revert InsecureLimit();
		_;
	}

	constructor(
		string memory name, 
		string memory description, 
		string memory imageUri
		){
			feedEURtoETH = AggregatorV3Interface(
            	0x1b44F3514812d835EB1BDB0acB33d3fA3351Ee43
			);
			feedUSDtoETH = AggregatorV3Interface(
            	0x1b44F3514812d835EB1BDB0acB33d3fA3351Ee43
        	);
			metadata = MetaData(name, description, imageUri);
	}

	function convert(uint256 amount, int256 rate) internal view{
		if (rate <= 0) revert InvalidChainLinkRate();
		return (amount * uint256(rate) / chainLinkDecimals);
	}

	function updateChainLinkDecimals(uint256 amount) onlyOwner external{
		chainLinkDecimals = amount;
	}
	function getLatestEurToETH(uint256 amount) internal view returns (int) {
        (
            int256 answer,
        ) = feedEURtoETH.latestRoundData();

        return convert(amount, answer);
    }

	function getLatestUSDToETH(uint256 amount) internal view returns (int){
        (
            int256 answer,
        ) = feedUSDtoETH.latestRoundData();
        return convert(amount, answer);
    }

	function setMinDeposit(string calldata currency, uint256 amount) external onlyOwner{
		if (kbacc256(currency) == kbacc256("USD")) minDeposit = getLatestUSDToETH(amount);
		else if (kbacc256(currency) == kbacc256("EUR")) minDeposit = getLatestEurToETH(amount);
	}

	function setWithdrawalBlockLimit(uint256 limit) external {
		if (limit < standardBlockLimit) revert InsecureLimit();
		withdrawalBlockLimit[msg.sender] = limit;
	}

	function getWithdrawalBlockLimit() external view returns (uint256) {
		uint256 limit = withdrawalBlockLimit[msg.sender];
		return limit == 0 ? standardBlockLimit : limit;
	}

    function withdrawFunds(uint256 amount) public virtual onlyOwner secureWithdrawal{
		if (address(this).balance < amount || amount == 0) revert InsufficientFunds(amount, address(this).balance);
        previousWithdrawalBlock[msg.sender] = block.number;
		_sendEth(amount);
      	emit Withdrawal(msg.sender, amount);
    }

	function _sendEth(uint256 amount) internal nonReentrant{
        (bool success, ) = payable(msg.sender).call{value: amount}("");
        if (!success) revert TransferFailed();
	}

	function depositFunds() public payable virtual {
		if (msg.value < minDeposit || msg.value == 0) revert InsufficientDeposit();
      	emit Deposit(msg.sender, msg.value);
    }

    fallback() external payable{
        depositFunds();
    }
    
    receive() external payable{
        depositFunds();
    }

}
