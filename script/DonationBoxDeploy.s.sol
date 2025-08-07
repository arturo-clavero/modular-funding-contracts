//SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "../../src/utils/FundErrors.sol";
import {Script} from "forge-std/Script.sol";
import {FundConstants} from "../test/utils/FundConstants.sol";
import {DonationBox} from "../src/modules/DonationBox.sol";

contract DonationBoxDeploy is Script {
    function run() external returns (DonationBox) {
        vm.startBroadcast();
        DonationBox donationBox =
            new DonationBox(FundConstants.NAME, FundConstants.DESCRIPTION, vm.envAddress("USD_PRICE_FEED_ADDRESS"));
        vm.stopBroadcast();
        return donationBox;
    }
}
