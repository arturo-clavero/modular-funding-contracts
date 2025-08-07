// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {DonationBox} from "../modules/DonationBox.sol";
import {Vault} from "../modules/Vault.sol";
import {CrowdFunding} from "../modules/CrowdFunding.sol";

/// @title FundFactory
/// @notice Factory contract to deploy and register various fund types
contract FundFactory {
    /// @notice Array of all deployed fund contract addresses
    address[] public deployedFundContracts;

    /// @notice Emitted when a new fund contract is created
    /// @param newContract Address of the newly deployed contract
    /// @param owner Address of the sender (creator)
    event FundContractCreated(address indexed newContract, address indexed owner);

    /// @dev Internal function to register a deployed fund contract
    /// @param newFundContract Address of the new contract
    function registerContract(address newFundContract) internal {
        deployedFundContracts.push(newFundContract);
        emit FundContractCreated(newFundContract, msg.sender);
    }

    /// @notice Creates a new DonationBox contract
    /// @param name The name of the fund
    /// @param description A description of the fund
    function createDonationBox(string memory name, string memory description, address priceFeed) external {
        DonationBox newFundContract = new DonationBox(name, description, priceFeed);
        registerContract(address(newFundContract));
    }

    /// @notice Creates a new Vault contract
    /// @param name The name of the vault
    /// @param description A description of the vault
    function createVault(string memory name, string memory description, address priceFeed) external {
        Vault newFundContract = new Vault(name, description, priceFeed);
        registerContract(address(newFundContract));
    }

    /// @notice Creates a new CrowdFunding contract
    /// @param _target Funding target (in wei)
    /// @param _seconds Seconds to include in deadline duration
    /// @param _minutes Minutes to include in deadline duration
    /// @param _hours Hours to include in deadline duration
    /// @param _days Days to include in deadline duration
    /// @param _weeks Weeks to include in deadline duration
    /// @param _gracePeriod Extra time after deadline for final deposits (in seconds)
    /// @param _whiteList Optional whitelist addresses for restricted access
    /// @param name The name of the crowdfunding campaign
    /// @param description A description of the campaign
    function createCrowdFundingContract(
        uint256 _target,
        uint256 _seconds,
        uint256 _minutes,
        uint256 _hours,
        uint256 _days,
        uint256 _weeks,
        uint256 _gracePeriod,
        address[] memory _whiteList,
        string memory name,
        string memory description,
        address priceFeed
    ) external {
        CrowdFunding newFundContract = new CrowdFunding(
            _target, _seconds, _minutes, _hours, _days, _weeks, _gracePeriod, _whiteList, name, description, priceFeed
        );
        registerContract(address(newFundContract));
    }
}
