//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {FundBase} from '../base/FundBase.sol';
import "../utils/FundErrors.sol"; 

/// @title DonationBox - Tip jar for giving ETH donations to owner
/// @notice Anyone can donate ETH, only owner can withdraw
contract DonationBox is FundBase{

    function withdrawAllFunds() external {
        withdrawFunds(address(this).balance);
    }
	
}
