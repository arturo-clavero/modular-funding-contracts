//SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "../../src/utils/FundErrors.sol";
import {Script} from "forge-std/Script.sol";
import {FundConstants} from "../test/utils/FundConstants.sol";
import {Vault} from "../src/modules/Vault.sol";
import {NetworkConfig} from "./NetworkConfig.s.sol";

contract VaultDeploy is Script {
    NetworkConfig public config;

    function run() external returns (Vault) {
        if (address(config) == address(0)) {
            config = new NetworkConfig();
        }
        vm.startBroadcast();
        Vault vault = new Vault(FundConstants.NAME, FundConstants.DESCRIPTION, config.getPriceFeed());
        vm.stopBroadcast();
        return vault;
    }
}
