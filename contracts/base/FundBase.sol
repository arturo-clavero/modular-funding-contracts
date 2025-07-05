//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "../utils/FundErrors.sol"; 

/// @title FundBase - Abstract base contract for fund logic
/// @notice Stores owner and provides internal ETH sending function
contract FundBase is ReentrancyGuard, Ownable{
    address immutable private owner;

    event Deposit(address indexed from, uint256 amount);
    event Withdrawal(address indexed to, uint256 amount);

    constructor() {
        owner = msg.sender;
    }

    function depositFunds() public payable virtual {
		if (msg.value == 0) revert ZeroValueNotAllowed();
      	emit Deposit(msg.sender, msg.value);
    }

    function withdrawFunds(uint256 amount) public onlyOwner virtual {
		if (address(this).balance < amount || amount == 0) revert InsufficientFunds(amount, address(this).balance);
        sendEth(amount);
      	emit Withdrawal(msg.sender, amount);
    }

	function sendEth(uint256 amount) public nonReentrant{
        (bool success, ) = payable(msg.sender).call{value: amount}("");
        if (!success) revert TransferFailed();
	}

    fallback() external payable{
        depositFunds();
    }
    
    receive() external payable{
        depositFunds();
    }

}
