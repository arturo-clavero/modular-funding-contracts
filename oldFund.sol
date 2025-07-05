//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract Funds{
    address owner;
    uint256 private minFundValue = 10;
    mapping(address => uint256) private funds;
    constructor(uint256 _minFundValue){
        owner = msg.sender;
        setMinimumFundValue(_minFundValue);
    }
    function setMinimumFundValue(uint256 amount) public{
        require (msg.sender == owner, "You do not have the authority to change minimum funds");
        if (amount >= 10)
            minFundValue = amount;
    }
    function depositFunds(  ) external payable{
        require(msg.value >= minFundValue, "Insufficient fund value");
        funds[msg.sender] += msg.value;
    }
    function withdrawFunds(uint256 amount) external payable{
        //check correct amount
        require(address(this).balance >= amount && amount > 0, "Not enough ETH");
        //check correct recipient
        require(msg.sender == owner, "not allowed");
        //try to send
        (bool success, ) = payable(msg.sender).call{value: amount}("");
        require(success, "ETH transfer failed");
        //clear other vals
        funds[msg.sender] -= amount;
    }
}