//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

library PriceConverter{
	error InvalidChainLinkRate();
	error UnsupportedCurrency();

	struct ConverterData {
		AggregatorV3Interface priceFeedEur;
		AggregatorV3Interface priceFeedUSD;
	}

	function initialize(ConverterData storage self){
		self.priceFeedEur = AggregatorV3Interface(
            	0x1b44F3514812d835EB1BDB0acB33d3fA3351Ee43
			);
		self.priceFeedUSD = AggregatorV3Interface(
            	0x1b44F3514812d835EB1BDB0acB33d3fA3351Ee43
			);
	}

	function getRates(
		ConverterData storage self,
		string calldata currency, 
		uint256 amount
		) internal view returns (uint256){
		if (keccak256(bytes(currency)) == keccak256(bytes("USD"))) 
			return getLatestPrice(self.priceFeedUSD, amount);
		else if (keccak256(bytes(currency)) == keccak256(bytes("EUR"))) 
			return getLatestPrice(self.priceFeedEur, amount);
		else
			revert UnsupportedCurrency();
	}

	function getLatestPrice(
		AggregatorV3Interface priceFeed,
		uint256 amount
    ) internal view returns (uint256) {
        (
            ,
            int256 answer,
            ,
            ,
            
        ) = priceFeed.latestRoundData();
        return convert(amount, answer, 1e8);
    }

	function convert(
			uint256 amount,
			int256 rate,
			uint256 chainLinkDecimals
		) internal pure returns (uint256) {
			if (rate <= 0) revert InvalidChainLinkRate();
			return (amount * uint256(rate)) / chainLinkDecimals;
		}
	
}
