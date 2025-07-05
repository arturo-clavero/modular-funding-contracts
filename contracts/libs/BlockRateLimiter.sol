//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

library BlockRateLimiter{
	error InsecureLimit();

	uint256 internal constant DEFAULT_LIMIT = 3;

	struct LimitData {
        mapping(address => uint256) lastBlock;
        mapping(address => uint256) customLimit;
    }
	
	function secureWithdrawal(
        LimitData storage self,
		address user
    ) internal {
        uint256 limit = self.customLimit[msg.sender];
        if (limit == 0) 
			limit = DEFAULT_LIMIT;
        if (block.number < self.lastBlock[msg.sender] + limit) 
			revert InsecureLimit();
		self.lastBlock[user] = block.number;
    }

	function setLimit(
		LimitData storage self,
		uint256 limit
		) internal {
			if (limit < DEFAULT_LIMIT) revert InsecureLimit();
			self.customLimit[msg.sender] = limit;
	}

	function getLimit(LimitData storage self) internal view returns (uint256) {
		uint256 limit = self.customLimit[msg.sender];
		return limit == 0 ? DEFAULT_LIMIT : limit;
	}
}