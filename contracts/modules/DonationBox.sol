// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {FundBase} from '../base/FundBase.sol';
import "../utils/FundErrors.sol";

/// @title DonationBox
/// @notice Simple tip jar contract allowing anyone to donate ETH; only owner can withdraw funds
contract DonationBox is FundBase {

    /// @notice Constructs the DonationBox with metadata
    /// @param name The name of the donation box or campaign
    /// @param description A short description of the donation purpose
    /// @param imageUri URI for an optional image representing the donation box
    constructor(
        string memory name, 
        string memory description,
        string memory imageUri
    ) FundBase(name, description, imageUri) {}

    /// @notice Withdraws all ETH funds from the contract to the owner
    /// @dev Calls `withdrawFunds` from FundBase with entire balance
    function withdrawAllFunds() external {
        withdrawFunds(address(this).balance);
    }
}
