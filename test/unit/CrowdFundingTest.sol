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

    function setWhitelist() private {
        vm.startPrank(owner);
        crowdFunding.enableWhiteList();
        // arr[0] = whitelisteduser;
        arr.push(whitelisteduser);
        crowdFunding.addWhiteList(arr);
        vm.stopPrank();
    }

    modifier whiteList(){
        vm.startPrank(owner);
        crowdFunding.enableWhiteList();
        // arr[0] = whitelisteduser;
        arr.push(whitelisteduser);
        crowdFunding.addWhiteList(arr);
        vm.stopPrank();
        _;
    }

    function testConstructorInitializesCorrectly() public {
        assertEq(crowdFunding.target(), FundConstants.TARGET);
        assertEq(crowdFunding.isWhiteListed(), false);
        assertEq(crowdFunding.deadline() > block.timestamp, true);
    }

    function testCrowdFundingConstructorValues() public {
        assertEq(crowdFunding.target(), FundConstants.TARGET);
        uint256 expectedDeadline = block.timestamp 
            + FundConstants.SECONDS 
            + FundConstants.MINUTES * 1 minutes
            + FundConstants.HOURS * 1 hours
            + FundConstants.DAYS * 1 days
            + FundConstants.WEEKS * 1 weeks;

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

    function testDepositCF() public{
        deal(address(this), 0);
        uint256 prevBalance = address(this).balance;
        uint256 funds = 0;
        hoax(user, 10);
        console.log("user balance: ", address(user).balance);
        crowdFunding.depositFunds{value: funds}();
        console.log("prev balance: ", prevBalance);
        console.log("diff: ", address(this).balance - prevBalance);
        console.log("curr: ", address(this).balance);
        assertEq(prevBalance + funds, address(this).balance);
    }

    function testWhiteListedCanFund() public whiteList(){
    // function testWhiteListedCanFund() public {
        // setWhitelist();
        deal(address(this), 0);
        uint256 prevBalance = address(this).balance;
        uint256 funds = 1;
        // hoax(whitelisteduser, 10);
        vm.prank(owner);
        crowdFunding.disableWhiteList();
        deal(whitelisteduser, 10);
        vm.prank(whitelisteduser);
        crowdFunding.depositFunds{value: funds}();
        console.log("prev balance: ", prevBalance);
        console.log("diff: ", address(this).balance - prevBalance);
        console.log("curr: ", address(this).balance);
        assertEq(prevBalance + funds, address(this).balance);
    }

    function testBlackListedCanNotFund() public whiteList(){
            uint256 prevBalance = address(this).balance;
        uint256 funds = 1;
        vm.prank(owner);
        crowdFunding.removeWhiteListFounder(whitelisteduser);
        vm.prank(whitelisteduser);
        vm.expectRevert();
        crowdFunding.depositFunds{value: funds}();
        assertEq(prevBalance, address(this).balance);
    }

    function testNonWhiteListedCanNotFund() public whiteList(){
        uint256 prevBalance = address(this).balance;
        uint256 funds = 1;
        vm.prank(user);
        vm.expectRevert();
        crowdFunding.depositFunds{value: funds}();
        assertEq(prevBalance, address(this).balance);
    }

     function testNonWhiteListedCanFundAfterDisable() public whiteList(){
        uint256 prevBalance = address(this).balance;
        uint256 funds = 1;
        vm.prank(owner);
        crowdFunding.disableWhiteList();
        vm.prank(user);
        crowdFunding.depositFunds{value: funds}();
        assertEq(prevBalance + funds, address(this).balance);
    }

    function testOwnerCanWithdrawAfterGoalReached() public whiteList() {
        vm.prank(whitelisteduser);
        crowdFunding.depositFunds{value: FundConstants.TARGET}();
        vm.prank(owner);
        crowdFunding.withdrawFunds();
        assertEq(address(crowdFunding).balance, 0);
    }

    function testOwnerCanNotWithdrawBeforeGoalReached() public whiteList() {
        vm.deal(address(this), 0);
        vm.prank(whitelisteduser);
        crowdFunding.depositFunds{value: FundConstants.TARGET - 1}();
        uint256 prevBalance = address(this).balance;
        vm.prank(owner);
        vm.expectRevert();
        crowdFunding.withdrawFunds();
        assertEq(address(crowdFunding).balance, prevBalance);
    }

    function testManualCancelAfterGracePeriod() public {
        skip(crowdFunding.gracePeriod() + 1);
        vm.prank(owner);
        crowdFunding.manuallyCancelCampaign();
        assertTrue(crowdFunding.isCancelled());
    }

    function testEndCampaignTriggersCancelIfGoalNotReached() public {
        skip(crowdFunding.deadline() + 1);
        crowdFunding.performUpkeep("");
        assertTrue(crowdFunding.isCancelled());
    }

    function testClaimRefundOnlyAfterCancellation() public whiteList() {
        vm.prank(whitelisteduser);
        crowdFunding.depositFunds{value: 1 ether}();
        skip(crowdFunding.gracePeriod() + 1);
        vm.prank(owner);
        crowdFunding.manuallyCancelCampaign();
        
        uint256 balanceBefore = whitelisteduser.balance;
        vm.prank(whitelisteduser);
        crowdFunding.claimRefund();
        assertGt(whitelisteduser.balance, balanceBefore);
    }

    function testCheckUpkeepReturnsTrueAfterDeadline() public {
        skip(crowdFunding.deadline() + 1);
        (bool upkeepNeeded, ) = crowdFunding.checkUpkeep("");
        assertTrue(upkeepNeeded);
    }

    function testGetCampaignStatusReturnsCorrectData() public {
        (uint256 t,,bool e,bool c,,,) = crowdFunding.getCampaignStatus();
        assertEq(t, crowdFunding.target());
        assertEq(e, false);
        assertEq(c, false);
    }

}