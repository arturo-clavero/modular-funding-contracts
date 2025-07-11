// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "forge-std/console.sol";

/// @title BlockRateLimiter
/// @notice A lightweight library to enforce per-address withdrawal rate limits based on block numbers
/// @dev Uses a `LimitData` struct stored in the parent contract. Limits are enforced using `msg.sender`.
library BlockRateLimiter {
    /// @dev Thrown when a limit is too low or not enough blocks have passed
    error InsecureLimit();
    error LimitBreached(uint256, uint256, uint256);

    /// @notice Default block limit if no custom limit is set
    uint256 internal constant DEFAULT_LIMIT = 3;

    /// @notice Stores last withdrawal block and custom limits per address
    struct LimitData {
        mapping(address => uint256) lastBlock;
        mapping(address => uint256) customLimit;
    }

    /// @notice Enforces block spacing between withdrawals
    /// @dev Uses `msg.sender` to enforce limit, but updates timestamp for `user` (used in owner-withdraw context)
    /// @param self The `LimitData` storage struct from the parent contract
    /// @param user The address whose last block should be updated (usually the owner)
    function secureWithdrawal(LimitData storage self, address user) internal {
        uint256 limit = self.customLimit[msg.sender];
        uint256 last = self.lastBlock[msg.sender];
        bool firstTime;

        if (last == 0) {
            if (limit == 0) {
                self.customLimit[msg.sender] = DEFAULT_LIMIT;
            }
            firstTime = true;
        }
        if (!firstTime && block.number < last + limit - 1) {
            revert LimitBreached(block.number, last, limit);
        }
        self.lastBlock[user] = block.number + 1;
    }

    /// @notice Sets a custom block limit for the caller
    /// @param self The `LimitData` storage struct from the parent contract
    /// @param limit The custom block interval between allowed withdrawals
    function setLimit(LimitData storage self, uint256 limit) internal {
        if (limit < DEFAULT_LIMIT) revert InsecureLimit();
        self.customLimit[msg.sender] = limit;
    }

    /// @notice Gets the current block limit for the caller
    /// @param self The `LimitData` storage struct from the parent contract
    /// @return The caller's custom limit, or the default if not set
    function getLimit(LimitData storage self) internal view returns (uint256) {
        uint256 limit = self.customLimit[msg.sender];
        return limit == 0 ? DEFAULT_LIMIT : limit;
    }
}
