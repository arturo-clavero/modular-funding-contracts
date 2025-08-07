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

    function setUp() public {
        creator = vm.addr(1);
        vm.prank(creator);

        factory = new FundFactory();

        // Deploy mock Chainlink price feed: 8 decimals, starting price $2000
        mockPriceFeed = new MockV3Aggregator(8, 2000e8);
    }

    function testCreateDonationBox() public {
        vm.prank(creator);
        factory.createDonationBox("Help Kids", "For children's education", address(mockPriceFeed));

        address[] memory deployed = getDeployedContracts();
        assertEq(deployed.length, 1);
        assertTrue(deployed[0] != address(0));
    }

    function testCreateVault() public {
        vm.prank(creator);
        factory.createVault("Secure Fund", "Vault for emergency savings", address(mockPriceFeed));

        address[] memory deployed = getDeployedContracts();
        assertEq(deployed.length, 1);
        assertTrue(deployed[0] != address(0));
    }

    function testCreateCrowdFunding() public {
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

        address[] memory deployed = getDeployedContracts();
        assertEq(deployed.length, 1);
        assertTrue(deployed[0] != address(0));
    }

    /// @dev Helper to get deployed contracts via storage read
    function getDeployedContracts() internal returns (address[] memory) {
        uint256 count = factory.getDeployedContractsCount();
        address[] memory deployed = new address[](count);
        for (uint256 i = 0; i < count; i++) {
            deployed[i] = factory.deployedFundContracts(i);
        }
        return deployed;
    }
}
