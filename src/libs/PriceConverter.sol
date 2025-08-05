// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";

library PriceConverter {
    error InvalidChainLinkRate();
    error InvalidAmount();
    error UnsupportedCurrency();

    function getRates(uint256 amount, string calldata currency, address priceFeed) external view returns (uint256) {
        if (amount == 0) {
            revert InvalidAmount();
        }
        if (keccak256(bytes(currency)) == keccak256(bytes("USD"))) {
            return getLatestPrice(AggregatorV3Interface(priceFeed), amount);
        } else {
            revert UnsupportedCurrency();
        }
    }

    function getLatestPrice(AggregatorV3Interface priceFeed, uint256 amount) internal view returns (uint256) {
        (, int256 answer,,,) = priceFeed.latestRoundData();

        return convert(amount, answer, 1e8);
    }

    function convert(uint256 amount, int256 rate, uint256 chainLinkDecimals) internal pure returns (uint256) {
        if (rate <= 0) revert InvalidChainLinkRate();
        return (amount * uint256(rate)) / chainLinkDecimals;
    }
}
