// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

/// @title PriceConverter
/// @notice Library for converting fiat currency amounts to wei using Chainlink price feeds
library PriceConverter {
	/// @dev Error thrown when Chainlink price feed returns invalid data
	error InvalidChainLinkRate();

	/// @dev Error thrown when an unsupported currency code is requested
	error UnsupportedCurrency();

	/// @notice Holds Chainlink price feed interfaces for supported currencies
	struct ConverterData {
		AggregatorV3Interface priceFeedEur;
		AggregatorV3Interface priceFeedUSD;
	}

	/// @notice Initializes price feed interfaces in the provided `ConverterData` struct
	/// @param self The `ConverterData` struct to initialize
	function initialize(ConverterData storage self) internal {
		// Example aggregator addresses (both set to same for now, adjust per network)
		self.priceFeedEur = AggregatorV3Interface(
			0x1b44F3514812d835EB1BDB0acB33d3fA3351Ee43
		);
		self.priceFeedUSD = AggregatorV3Interface(
			0x1b44F3514812d835EB1BDB0acB33d3fA3351Ee43
		);
	}

	/// @notice Converts a fiat amount in given currency to wei based on Chainlink price feed
	/// @param self The `ConverterData` struct containing price feeds
	/// @param currency The fiat currency code (e.g., "USD" or "EUR")
	/// @param amount The amount in fiat currency units (without decimals)
	/// @return The equivalent amount in wei
	/// @dev Reverts if currency is unsupported
	function getRates(
		ConverterData storage self,
		string calldata currency,
		uint256 amount
	) internal view returns (uint256) {
		if (keccak256(bytes(currency)) == keccak256(bytes("USD"))) {
			return getLatestPrice(self.priceFeedUSD, amount);
		} else if (keccak256(bytes(currency)) == keccak256(bytes("EUR"))) {
			return getLatestPrice(self.priceFeedEur, amount);
		} else {
			revert UnsupportedCurrency();
		}
	}

	/// @notice Retrieves the latest price from a Chainlink price feed and converts the fiat amount
	/// @param priceFeed The Chainlink price feed interface
	/// @param amount The amount in fiat currency units (without decimals)
	/// @return The equivalent amount in wei
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

	/// @notice Converts a fiat amount multiplied by a price rate and normalizes decimals
	/// @param amount The amount in fiat currency units (without decimals)
	/// @param rate The price rate from Chainlink feed (int256)
	/// @param chainLinkDecimals The decimals precision used by the price feed (usually 1e8)
	/// @return The converted amount in wei
	/// @dev Reverts if rate is zero or negative
	function convert(
		uint256 amount,
		int256 rate,
		uint256 chainLinkDecimals
	) internal pure returns (uint256) {
		if (rate <= 0) revert InvalidChainLinkRate();
		return (amount * uint256(rate)) / chainLinkDecimals;
	}
}
