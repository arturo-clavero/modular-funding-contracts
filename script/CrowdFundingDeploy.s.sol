//SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "../../src/utils/FundErrors.sol";
import {Script} from "forge-std/Script.sol";
import {FundConstants} from "../test/utils/FundConstants.sol";
import {CrowdFunding} from "../src/modules/CrowdFunding.sol";

contract CrowdFundingDeploy is Script {
    function run() external returns (CrowdFunding) {
        vm.startBroadcast();
        address[] memory arr;
        CrowdFunding crowdFunding = new CrowdFunding(
            FundConstants.TARGET,
            FundConstants.SECONDS,
            FundConstants.MINUTES,
            FundConstants.HOURS,
            FundConstants.DAYS,
            FundConstants.WEEKS,
            FundConstants.GRACE_PERIOD,
            arr,
            FundConstants.NAME, 
            FundConstants.DESCRIPTION, 
            vm.envAddress("USD_PRICE_FEED_ADDRESS")
        );
        vm.stopBroadcast();
        return crowdFunding;
    }
}
