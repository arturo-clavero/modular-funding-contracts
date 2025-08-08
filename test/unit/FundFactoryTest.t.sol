// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../../src/base/FundFactory.sol";
import "../../src/modules/DonationBox.sol";
import "../../src/modules/Vault.sol";
import "../../src/modules/CrowdFunding.sol";
import {MockV3Aggregator} from "../mocks/MockV3Aggregator.sol";

contract FundFactoryTest is Test {
    FundFactory public factory;
    MockV3Aggregator public mockPriceFeed;
    address[] public arr;
    address public creator;

    function setUp() external {
        creator = vm.addr(1);
        vm.prank(creator);

        factory = new FundFactory();

        mockPriceFeed = new MockV3Aggregator(8, 2000e8);
    }

    function testCreateDonationBox() external {
        vm.prank(creator);
        factory.createDonationBox("NAME", "DESCRIPTION", address(mockPriceFeed));
    }

    function testCreateVault() external {
        vm.prank(creator);
        factory.createVault("Secure Fund", "Vault for emergency savings", address(mockPriceFeed));
    }

    function testCreateCrowdFunding() external {
        factory.createCrowdFundingContract(
            10 ether, // target
            0,
            0,
            0,
            0,
            1, // 1 week deadline
            3600, // 1 hour grace period
            arr,
            "Save the Forests",
            "Crowdfunding for reforestation",
            address(mockPriceFeed)
        );
    }
}
