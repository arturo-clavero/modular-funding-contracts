//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// @title FundBase - Abstract base contract for fund logic
/// @notice Stores owner and provides internal ETH sending function
contract FundBase{
    address immutable owner;

    /// @notice Sets the contract owner on deployment
    constructor() {
        owner = msg.sender;
    }

    /// @notice Internal helper to send ETH from the contract
    /// @param amount Amount of ETH to send
    /// @param recipient Address to receive the ETH
    /// @return success True if transfer succeeded
    function sendEth(uint256 amount, address recipient) internal returns (bool){
        require(address(this).balance >= amount && amount > 0, "Not enough funds");
        (bool success, ) = payable(recipient).call{value: amount}("");
        require(success, "Invalid ETH transfer");
        return success;
    }
}


