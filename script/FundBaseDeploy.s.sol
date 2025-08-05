//SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "../../src/utils/FundErrors.sol";
import {Script} from "forge-std/Script.sol";
import {FundConstants} from "../test/utils/FundConstants.sol";
import {FundBase} from "../src/base/FundBase.sol";

contract FundBaseAbstraction is FundBase {
    constructor(string memory name, string memory description, address priceFeed)
        FundBase(name, description, priceFeed)
    {}
}

contract FundBaseDeploy is Script {
    function run() external returns (FundBaseAbstraction) {
        vm.startBroadcast();
        FundBaseAbstraction fundBase = new FundBaseAbstraction(
            FundConstants.NAME, FundConstants.DESCRIPTION, vm.envAddress("USD_PRICE_FEED_ADDRESS")
        );
        vm.stopBroadcast();
        return fundBase;
    }
}
