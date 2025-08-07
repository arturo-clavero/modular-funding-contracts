//SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "../../src/utils/FundErrors.sol";
import {Test, console} from "forge-std/Test.sol";
import {DonationBox} from "../../src/modules/DonationBox.sol";
import {DonationBoxDeploy} from "../../script/DonationBoxDeploy.s.sol";
import {FundConstants} from "../utils/FundConstants.sol";

contract DonationBoxTest is Test {
    DonationBox public donationBox;
    address public owner;
    address public user = vm.addr(3);
    uint256 funds = 2;

    function setUp() public {
        DonationBoxDeploy donationBoxDeploy = new DonationBoxDeploy();
        donationBox = donationBoxDeploy.run();
        owner = address(msg.sender);
    }

    function testDepositDonationBox() public {
        uint256 prevBalance = address(donationBox).balance;
        hoax(user, 10);
        donationBox.depositFunds{value: funds}();
        assertEq(prevBalance + funds, address(donationBox).balance);
    }

    function testAllWithdrawal() public {
        testDepositDonationBox();
        uint256 prevBalanceVault = address(donationBox).balance;
        hoax(owner, 0);
        donationBox.withdrawAllFunds();
        assertEq(0, address(donationBox).balance);
        assertEq(owner.balance, prevBalanceVault);
    }

    function testAllWithdrawalNonOwner() public {
        testDepositDonationBox();
        uint256 prevBalanceVault = address(donationBox).balance;
        hoax(user, 0);
        vm.expectRevert();
        donationBox.withdrawAllFunds();
        assertEq(prevBalanceVault, address(donationBox).balance);
        assertEq(user.balance, 0);
    }

    function testWithdrawal() public {
        uint256 amount = funds / 2;
        testDepositDonationBox();
        uint256 prevBalanceVault = address(donationBox).balance;
        hoax(owner, 0);
        donationBox.withdrawFunds(amount);
        assertEq(prevBalanceVault - amount, address(donationBox).balance);
        assertEq(owner.balance, amount);
    }

    function testWithdrawalNonOwner() public {
        testDepositDonationBox();
        uint256 prevBalanceVault = address(donationBox).balance;
        hoax(user, 0);
        vm.expectRevert();
        donationBox.withdrawFunds(funds / 2);
        assertEq(prevBalanceVault, address(donationBox).balance);
        assertEq(user.balance, 0);
    }
}
