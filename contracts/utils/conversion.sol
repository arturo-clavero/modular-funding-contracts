//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";

contract ConversionRateEth{
    AggregatorV3Interface internal USD_ETH = AggregatorV3Interface(
            0x1b44F3514812d835EB1BDB0acB33d3fA3351Ee43
    );
    AggregatorV3Interface internal EUR_ETH = AggregatorV3Interface(
            0x1b44F3514812d835EB1BDB0acB33d3fA3351Ee43
    );
    uint8 ETH = 0;
    uint8 USD = 1;
    uint8 EUR = 2;

    constructor() {

    }
    function getConvertedRate(uint8 from, uint8 to, uint256 amount) public returns(uint256){
        require(from >= 1 && from <= 2 && to == 0 && amount > 0, "Invalid coins");
        if (from == USD && to == ETH){
             (
            int256 answer,
        ) = USD_ETH.latestRoundData();
        return answer * amount;
        }
        else if (from == EUR && to == ETH){
             (
            int256 answer,
        ) = EUR_ETH.latestRoundData();
        return answer * amount;
        }
    }
}