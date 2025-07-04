// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

error NotAuthorized();
error ZeroValueNotAllowed();
error InsufficientFunds(uint256 requestedAmount, uint256 availableFunds);
error InsufficientDeposit();
error TransferFailed();
error WithdrawalFailed();
error RefundFailed();
error CancelledAlready();
error EndedAlready();
error GoalNotReached();
error AllowGracePeriod();
error NotEligibleForRefund();
error InsecureLimit();
error UnsupportedCurrency();

