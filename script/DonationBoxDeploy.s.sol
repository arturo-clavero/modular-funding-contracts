//SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "../../src/utils/FundErrors.sol";
import {Script} from "forge-std/Script.sol";
import {FundConstants} from "../test/utils/FundConstants.sol";
import {DonationBox} from "../src/modules/DonationBox.sol";
import {NetworkConfig} from "./NetworkConfig.s.sol";

contract DonationBoxDeploy is Script {
    NetworkConfig public config;

    function run() external returns (DonationBox) {
        if (address(config) == address(0)) {
            config = new NetworkConfig();
        }
        vm.startBroadcast();
        DonationBox donationBox = new DonationBox(FundConstants.NAME, FundConstants.DESCRIPTION, config.getPriceFeed());
        vm.stopBroadcast();
        return donationBox;
    }
}
