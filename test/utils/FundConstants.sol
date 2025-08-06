// src/utils/FundConstants.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

library FundConstants {
    string public constant NAME = "My Fund";
    string public constant DESCRIPTION = "A decentralized funding pool";
    uint256 public constant TARGET = 10 ether;
    uint256 public constant SECONDS = 30;
    uint256 public constant MINUTES = 2;
    uint256 public constant HOURS = 1;
    uint256 public constant DAYS = 0;
    uint256 public constant WEEKS = 0;
    uint256 public constant GRACE_PERIOD = 300;//seconds
}
