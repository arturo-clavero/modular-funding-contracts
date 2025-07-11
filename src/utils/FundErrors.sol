// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// @notice Thrown when the caller is not authorized to perform an action
error NotAuthorized();

/// @notice Thrown when a zero value input is provided where not allowed
error ZeroValueNotAllowed();

/// @notice Thrown when a withdrawal or operation requests more funds than available
/// @param requestedAmount The amount requested
/// @param availableFunds The amount currently available
error InsufficientFunds(uint256 requestedAmount, uint256 availableFunds);

/// @notice Thrown when a deposit amount does not meet minimum required
error InsufficientDeposit();

/// @notice Thrown when ETH transfer fails
error TransferFailed();

/// @notice Thrown when withdrawal operation fails
error WithdrawalFailed();

/// @notice Thrown when refund operation fails
error RefundFailed();

/// @notice Thrown when an operation is attempted on a campaign that was already cancelled
error CancelledAlready();

/// @notice Thrown when an operation is attempted on a campaign that has already ended
error EndedAlready();

/// @notice Thrown when funding goal is not reached but withdrawal is attempted
error GoalNotReached();

/// @notice Thrown when action is attempted before grace period expires
error AllowGracePeriod();

/// @notice Thrown when a user is not eligible for a refund
error NotEligibleForRefund();

/// @notice Thrown when a withdrawal is attempted too soon according to rate limiting
error InsecureLimit();

/// @notice Thrown when an unsupported currency is requested for conversion
error UnsupportedCurrency();
