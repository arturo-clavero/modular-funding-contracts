//SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Script} from "forge-std/Script.sol";
import {FundBase} from "../../src/base/FundBase.sol";

contract DeployFundBase is Script {
	FundBase public fundBase;

	function setUp() external {

	}

	function run() external {
		vm.startBroadcast();
		fundBase = new FundBase(msg.sender);
		vm.stopBroadcast();
	}
}