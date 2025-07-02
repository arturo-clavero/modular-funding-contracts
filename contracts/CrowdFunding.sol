//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {FundBase} from './FundBase.sol';

/// @title Crowdfunding - Campaign contract with refund logic
/// @notice Accepts user funds toward a target; allows refunds if cancelled
contract Crowdfunding is FundBase{
    uint256 immutable target;
    bool isCancelled = false;

    // Track each user's contribution
    mapping (address => uint256) private funds;

    /// @param _target Funding goal in wei
    constructor(uint256 _target) FundBase(){
        target = _target;
    }

    /// @notice Allows users to contribute to the campaign
    function depositFunds() public payable{  
        require(msg.value > 0, "Must send ETH");   
        funds[msg.sender] += msg.value;
    }

    /// @notice Allows owner to withdraw all funds if target reached and not cancelled
    function withdrawFunds()public {
        require (msg.sender == owner, "Not authorized for withdrawal");
        require (!isCancelled, "Crowdfunding was cancelled");
        require(target <= address(this).balance, "Not enough funds to withdraw");
        sendEth(address(this).balance, msg.sender);
    }

    /// @notice Owner can cancel the campaign (enables refunds)
    function cancel()public {
        require(msg.sender == owner, "Not authorized");
        isCancelled = true;
    }

    /// @notice Contributors can claim a refund if campaign was cancelled
    function claimRefund()public {
        require(isCancelled && funds[msg.sender] > 0, "Not eligible for refund");
        require(sendEth(funds[msg.sender], msg.sender), "");
        delete funds[msg.sender];
    }
}
