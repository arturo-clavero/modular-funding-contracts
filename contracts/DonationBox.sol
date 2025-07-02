//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {FundBase} from './FundBase.sol';

/// @title DonationBox - Tip jar for giving ETH donations to owner
/// @notice Anyone can donate ETH, only owner can withdraw
contract DonationBox is FundBase{
    constructor() FundBase(){}

    /// @notice Accepts ETH donations from anyone
    function depositFunds() external payable {
        require(msg.value > 0, "Must send ETH");
    }

    /// @notice Allows owner to withdraw a specific amount
    /// @param amount Amount of ETH to withdraw
    function withdrawFunds(uint256 amount) public returns (bool){
        require (msg.sender == owner, "Not authorized for withdrawal");
        return sendEth(amount, owner);
    }

    /// @notice Allows owner to withdraw full contract balance
    function withdrawAllFunds() external returns (bool){
        return withdrawFunds(address(this).balance);
    }
}
