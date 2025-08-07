//SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "../../src/utils/FundErrors.sol";
import {Test, console} from "forge-std/Test.sol";
import {CrowdFunding} from "../../src/modules/CrowdFunding.sol";
import {CrowdFundingDeploy} from "../../script/CrowdFundingDeploy.s.sol";
import {FundConstants} from "../utils/FundConstants.sol";

contract CrowdFundingTest is Test {
    CrowdFunding public crowdFunding;
    address public owner;
    address public whitelisteduser = vm.addr(2);
    address public user = vm.addr(3);
    address[] public arr;

    function setUp() public {
        CrowdFundingDeploy crowdFundingDeploy = new CrowdFundingDeploy();
        crowdFunding = crowdFundingDeploy.run();
        owner = address(msg.sender);
    }

    modifier whiteList() {
        vm.startPrank(owner);
        crowdFunding.enableWhiteList();
        arr.push(whitelisteduser);
        crowdFunding.addWhiteList(arr);
        vm.stopPrank();
        _;
    }

    function testConstructorInitializesCorrectly() public view {
        assertEq(crowdFunding.target(), FundConstants.TARGET);
        assertEq(crowdFunding.isWhiteListed(), false);
        assertEq(crowdFunding.deadline() > block.timestamp, true);
    }

    function testCrowdFundingConstructorValues() public view {
        assertEq(crowdFunding.target(), FundConstants.TARGET);
        uint256 expectedDeadline = block.timestamp + FundConstants.SECONDS + FundConstants.MINUTES * 1 minutes
            + FundConstants.HOURS * 1 hours + FundConstants.DAYS * 1 days + FundConstants.WEEKS * 1 weeks;

        uint256 expectedGrace = expectedDeadline + FundConstants.GRACE_PERIOD;
        assertEq(crowdFunding.deadline(), expectedDeadline);
        assertEq(crowdFunding.gracePeriod(), expectedGrace);
        assertFalse(crowdFunding.isWhiteListed());
        // console.log("1.", crowdFunding.metaData);
        // console.log("2.", crowdFunding.metaData());

        // assertEq(crowdFunding.metaData.name, FundConstants.NAME);
        // assertEq(crowdFunding.metaData.description, FundConstants.DESCRIPTION);
    }

    function testOwnerCanEnableWhitelist() public {
        vm.prank(owner);
        crowdFunding.enableWhiteList();
        assertTrue(crowdFunding.isWhiteListed());
    }

    function testUserCanNotEnableWhitelist() public {
        vm.prank(user);
        vm.expectRevert();
        crowdFunding.enableWhiteList();
        assertFalse(crowdFunding.isWhiteListed());
    }

    function testOwnerCanDisableWhitelist() public {
        testOwnerCanEnableWhitelist();
        vm.prank(owner);
        crowdFunding.disableWhiteList();
        assertFalse(crowdFunding.isWhiteListed());
    }

    function testUserCanNotDisableWhitelist() public {
        testOwnerCanEnableWhitelist();
        vm.prank(user);
        vm.expectRevert();
        crowdFunding.disableWhiteList();
        assertTrue(crowdFunding.isWhiteListed());
    }

    function testDepositCrowdFunding() public {
        uint256 prevBalance = address(crowdFunding).balance;
        uint256 funds = 2;
        hoax(user, 10);
        crowdFunding.depositFunds{value: funds}();
        assertEq(prevBalance + funds, address(crowdFunding).balance);
    }

    function testWhiteListedCanFund() public whiteList {
        uint256 prevBalance = address(crowdFunding).balance;
        uint256 funds = 2;
        hoax(whitelisteduser, 10);
        crowdFunding.depositFunds{value: funds}();
        assertEq(prevBalance + funds, address(crowdFunding).balance);
    }

    function testBlackListedCanNotFund() public whiteList {
        uint256 prevBalance = address(crowdFunding).balance;
        uint256 funds = 2;
        vm.prank(owner);
        crowdFunding.removeWhiteListFounder(whitelisteduser);
        hoax(whitelisteduser, 10);
        vm.expectRevert();
        crowdFunding.depositFunds{value: funds}();
        assertEq(prevBalance, address(crowdFunding).balance);
    }

    function testNonWhiteListedCanNotFund() public whiteList {
        uint256 prevBalance = address(crowdFunding).balance;
        uint256 funds = 2;
        hoax(user, 10);
        vm.expectRevert();
        crowdFunding.depositFunds{value: funds}();
        assertEq(prevBalance, address(crowdFunding).balance);
    }

    function testNonWhiteListedCanFundAfterDisable() public whiteList {
        uint256 prevBalance = address(crowdFunding).balance;
        uint256 funds = 2;
        vm.prank(owner);
        crowdFunding.disableWhiteList();
        hoax(user, funds);
        crowdFunding.depositFunds{value: funds}();
        assertEq(prevBalance + funds, address(crowdFunding).balance);
    }

    function testOwnerCanWithdrawAfterGoalReached() public whiteList {
        hoax(whitelisteduser, FundConstants.TARGET);
        crowdFunding.depositFunds{value: FundConstants.TARGET}();
        hoax(owner, 0);
        crowdFunding.withdrawFunds();
        assertEq(address(crowdFunding).balance, 0);
        assert(owner.balance >= FundConstants.TARGET);
    }

    function testOwnerCanNotWithdrawBeforeGoalReached() public whiteList {
        vm.deal(address(crowdFunding), 0);
        hoax(whitelisteduser, FundConstants.TARGET);
        crowdFunding.depositFunds{value: FundConstants.TARGET - 1}();
        uint256 prevBalanceVault = address(crowdFunding).balance;
        uint256 prevBalanceOwner = address(owner).balance;
        vm.prank(owner);
        vm.expectRevert();
        crowdFunding.withdrawFunds();
        assertEq(address(crowdFunding).balance, prevBalanceVault);
        assertEq(owner.balance, prevBalanceOwner);
    }

    function testCanNotDepositAfterDeadline() public {
        uint256 funds = 2;
        skip(crowdFunding.deadline() + 1);
        hoax(user, funds);
        uint256 prevBalanceVault = address(crowdFunding).balance;
        uint256 prevBalanceUser = address(user).balance;
        vm.expectRevert();
        crowdFunding.depositFunds{value: funds}();
        assertEq(address(crowdFunding).balance, prevBalanceVault);
        assertEq(user.balance, prevBalanceUser);
    }

    function testCanNotManualCancelBetweenDeadlineGracePeriod() public {
        uint256 time = crowdFunding.deadline() + 1;
        skip(time);
        vm.prank(owner);
        vm.expectRevert();
        crowdFunding.manuallyCancelCampaign();
        assertFalse(crowdFunding.isCancelled());
        assertLt(time, crowdFunding.gracePeriod());
    }

    function testManualCancelAfterGracePeriod() public {
        skip(crowdFunding.gracePeriod() + 1);
        vm.prank(owner);
        crowdFunding.manuallyCancelCampaign();
        assertTrue(crowdFunding.isCancelled());
    }

    function testCancelAfterGracePeriod() public {
        uint256 funds = 1;
        skip(crowdFunding.gracePeriod() + 1);
        hoax(user, funds);
        uint256 prevBalanceVault = address(crowdFunding).balance;
        uint256 prevBalanceUser = address(user).balance;
        vm.expectRevert();
        crowdFunding.depositFunds{value: funds}();
        assertEq(address(crowdFunding).balance, prevBalanceVault);
        assertEq(user.balance, prevBalanceUser);
    }

    function testEndCampaignTriggersCancelIfGoalNotReached() public {
        skip(crowdFunding.gracePeriod() + 1);
        crowdFunding.performUpkeep("");
        assertTrue(crowdFunding.isCancelled());
    }

    function testClaimRefundOnlyAfterCancellation() public whiteList {
        uint256 funds = 1;
        hoax(whitelisteduser, funds);
        crowdFunding.depositFunds{value: funds}();
        skip(crowdFunding.gracePeriod() + 1);
        vm.prank(owner);
        crowdFunding.manuallyCancelCampaign();
        uint256 balanceBefore = whitelisteduser.balance;
        vm.prank(whitelisteduser);
        crowdFunding.claimRefund();
        assertEq(whitelisteduser.balance, balanceBefore + funds);
    }

    function testClaimRefundByDifferentFunders() public {
        uint256 totalFunders = 3;
        uint256[] memory funds = new uint256[](totalFunders);
        address[] memory funders = new address[](totalFunders);

        for (uint256 i = 0; i < totalFunders; i++) {
            address funder = vm.addr(i + 3);
            uint256 amount = 3 * (i + 1) * 2;
            funders[i] = funder;
            funds[i] = amount;
            vm.deal(funder, amount);
            vm.startPrank(funder);
            crowdFunding.depositFunds{value: amount / 2}();
            crowdFunding.depositFunds{value: amount / 2}();
            vm.stopPrank();
        }
        skip(crowdFunding.gracePeriod());
        vm.prank(owner);
        crowdFunding.manuallyCancelCampaign();
        assertTrue(crowdFunding.isCancelled());
        for (uint256 i = 0; i < totalFunders; i++) {
            address funder = funders[i];
            uint256 balanceBefore = funder.balance;
            vm.prank(funder);
            crowdFunding.claimRefund();
            assertEq(funder.balance, balanceBefore + funds[i]);
        }
    }

    function testCheckUpkeepReturnsTrueAfterDeadline() public {
        skip(crowdFunding.deadline() + 1);
        (bool upkeepNeeded,) = crowdFunding.checkUpkeep("");
        assertTrue(upkeepNeeded);
    }

    function testGetCampaignStatusReturnsCorrectData() public view {
        (uint256 t,, bool e, bool c,,,) = crowdFunding.getCampaignStatus();
        assertEq(t, crowdFunding.target());
        assertEq(e, false);
        assertEq(c, false);
    }
}
