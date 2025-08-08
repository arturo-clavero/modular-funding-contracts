//SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "../../src/utils/FundErrors.sol";
import {Test, console} from "forge-std/Test.sol";
import {FundBaseDeploy, FundBaseAbstraction} from "../../script/FundBaseDeploy.s.sol";
import {FundConstants} from "../utils/FundConstants.sol";
import {BlockRateLimiter} from "../../src/libs/BlockRateLimiter.sol";
import {PriceConverter} from "../../src/libs/PriceConverter.sol";

contract Rejector {
    fallback() external payable {
        revert("Reject ETH");
    }

    function trigger(FundBaseAbstraction fundBase, uint256 amount) external {
        fundBase.withdrawFunds(amount);
    }
}

contract FundBaseTestFork is Test {
    FundBaseAbstraction public fundBase;
    address public owner;

    uint256 max_user_id = 1;
    address public user = vm.addr(max_user_id);
    uint256 constant VALID_WITHDRAW_AMOUNT = 1;
    uint256 constant VALID_DOUBLE_WITHDRAW_AMOUNT = 1;
    uint256 constant FUND_AMOUNT = 10;
    uint256 constant VALID_BLOCK_LIMIT = BlockRateLimiter.DEFAULT_LIMIT + 1;
    uint256 constant INVALID_BLOCK_LIMIT = BlockRateLimiter.DEFAULT_LIMIT - 1;
    uint256 constant VALID_MIN_DEPOSIT = 5;
    string constant VALID_CURRENCY = "USD";
    string constant INVALID_CURRENCY = "x";
    address constant INVALID_PRICE_FEED = address(0);

    event Withdrawal(address indexed sender, uint256 amount);
    event Deposit(address indexed from, uint256 amount);

    modifier funded() {
        console.log("balance before funding:", address(fundBase).balance);
        address randomGuy = uniqueUser();
        hoax(randomGuy, FUND_AMOUNT);
        fundBase.depositFunds{value: FUND_AMOUNT}();
        _;
    }

    // function setUp() public {
    // vm.createSelectFork(vm.envString("SEPOLIA_URL"));
    // owner = address(0x1234);
    // vm.prank(owner);
    // fundBase = new FundBaseAbstraction(
    //     FundConstants.NAME, FundConstants.DESCRIPTION, vm.envAddress("USD_PRICE_FEED_ADDRESS")
    // );
    // console.log("balance at set up:", address(fundBase).balance);
    // max_user_id = 2;

    function setUp() external {
        FundBaseDeploy fundBaseDeploy = new FundBaseDeploy();
        fundBase = fundBaseDeploy.run();
        owner = address(msg.sender);
        max_user_id = 2;
    }

    function testSetMinDepositPrevSet() external {
        vm.prank(owner);
        fundBase.setMinDeposit(VALID_MIN_DEPOSIT * 2, VALID_CURRENCY);
        testSetMinDepositInvalidCurrency();
        testSetMinDepositInvalidAmount();
        testSetMinDeposit();
    }

    function testDepositFundsValidMinDeposit() external {
        testSetMinDeposit();
        address randomGuy = uniqueUser();
        uint256 rate = PriceConverter.getRates(VALID_MIN_DEPOSIT, VALID_CURRENCY, fundBase.priceFeedUSD());
        hoax(randomGuy, rate);
        uint256 initialBalance = randomGuy.balance;
        fundBase.depositFunds{value: rate}();
        assertEq(randomGuy.balance, initialBalance - rate);
    }

    function testDepositFundsInvalidMinDeposit() external {
        testSetMinDeposit();
        address randomGuy = uniqueUser();
        uint256 rate = PriceConverter.getRates(VALID_MIN_DEPOSIT, VALID_CURRENCY, fundBase.priceFeedUSD());
        hoax(randomGuy, rate - 1);
        uint256 initialBalance = randomGuy.balance;
        vm.expectRevert();
        fundBase.depositFunds{value: rate - 1}();
        assertEq(randomGuy.balance, initialBalance);
    }

    function testInvalidPriceFeedNew() external {
        vm.startPrank(user);
        FundBaseAbstraction fundBaseBadPriceFeed =
            new FundBaseAbstraction(FundConstants.NAME, FundConstants.DESCRIPTION, vm.addr(1));
        vm.expectRevert();
        fundBaseBadPriceFeed.setMinDeposit(VALID_MIN_DEPOSIT, VALID_CURRENCY);
        vm.stopPrank();
    }

    function testSetMinDeposit() public {
        uint256 prevMinDeposit = fundBase.minDeposit();
        vm.prank(owner);
        fundBase.setMinDeposit(VALID_MIN_DEPOSIT, VALID_CURRENCY);
        assertNotEq(fundBase.minDeposit(), prevMinDeposit);
    }

    function testSetMinDepositUnauthorized() public {
        uint256 prevMinDeposit = fundBase.minDeposit();
        vm.prank(user);
        vm.expectRevert();
        fundBase.setMinDeposit(VALID_MIN_DEPOSIT, VALID_CURRENCY);
        assertEq(fundBase.minDeposit(), prevMinDeposit);
    }

    function testSetMinDepositInvalidAmount() public {
        uint256 prevMinDeposit = fundBase.minDeposit();
        vm.prank(owner);
        vm.expectRevert();
        fundBase.setMinDeposit(0, VALID_CURRENCY);
        assertEq(fundBase.minDeposit(), prevMinDeposit);
    }

    function testSetMinDepositInvalidCurrency() public {
        uint256 prevMinDeposit = fundBase.minDeposit();
        vm.prank(owner);
        vm.expectRevert();
        fundBase.setMinDeposit(VALID_MIN_DEPOSIT, INVALID_CURRENCY);
        assertEq(fundBase.minDeposit(), prevMinDeposit);
    }

    function uniqueUser() private returns (address) {
        max_user_id++;
        return (vm.addr(max_user_id));
    }
}
