//SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "../../src/utils/FundErrors.sol";
import {Script} from "forge-std/Script.sol";
import {FundConstants} from "../test/utils/FundConstants.sol";
import {CrowdFunding} from "../src/modules/CrowdFunding.sol";
import {NetworkConfig} from "./NetworkConfig.s.sol";

contract CrowdFundingDeploy is Script {
    NetworkConfig public config;

    function run() external returns (CrowdFunding) {
        if (address(config) == address(0)) {
            config = new NetworkConfig();
        }
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
            config.getPriceFeed()
        );
        vm.stopBroadcast();
        return crowdFunding;
    }
}
