//SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "../../src/utils/FundErrors.sol";
import {Script} from "forge-std/Script.sol";
import {FundConstants} from "../test/utils/FundConstants.sol";
import {FundBase} from "../src/base/FundBase.sol";
import {NetworkConfig} from "./NetworkConfig.s.sol";

contract FundBaseAbstraction is FundBase {
    constructor(string memory name, string memory description, address priceFeed)
        FundBase(name, description, priceFeed)
    {}
}

contract FundBaseDeploy is Script {
    NetworkConfig public config;

    function run() external returns (FundBaseAbstraction) {
        if (address(config) == address(0)) {
            config = new NetworkConfig();
        }
        vm.startBroadcast();
        FundBaseAbstraction fundBase =
            new FundBaseAbstraction(FundConstants.NAME, FundConstants.DESCRIPTION, config.getPriceFeed());
        vm.stopBroadcast();
        return fundBase;
    }
}
