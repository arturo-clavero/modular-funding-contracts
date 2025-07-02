// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

error NotAuthorized();
error ZeroValueNotAllowed();
error InsufficientFunds(uint256 requestedAmount, uint256 availableFunds);
error TransferFailed();
error WithdrawalFailed();
error RefundFailed();
error CancelledAlready();
error GoalNotReached();
error NotEligibleForRefund();
