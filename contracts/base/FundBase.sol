//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "../utils/FundErrors.sol"; 

/// @title FundBase - Abstract base contract for fund logic
/// @notice Stores owner and provides internal ETH sending function
contract FundBase is ReentrancyGuard, Ownable{

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
		if (msg.value == 0) revert ZeroValueNotAllowed();
      	emit Deposit(msg.sender, msg.value);
    }

    fallback() external payable{
        depositFunds();
    }
    
    receive() external payable{
        depositFunds();
    }

}
