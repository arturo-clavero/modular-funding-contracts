//SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "../../src/utils/FundErrors.sol";
import {Script} from "forge-std/Script.sol";
import {FundConstants} from "../test/utils/FundConstants.sol";
import {Vault} from "../src/modules/Vault.sol";

contract VaultDeploy is Script {
    function run() external returns (Vault) {
        vm.startBroadcast();
        Vault vault = new Vault(FundConstants.NAME, FundConstants.DESCRIPTION, vm.envAddress("USD_PRICE_FEED_ADDRESS"));
        vm.stopBroadcast();
        return vault;
    }
}
