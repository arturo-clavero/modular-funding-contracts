//SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "../../src/utils/FundErrors.sol";
import {Test, console} from "forge-std/Test.sol";
import {FundBase} from "../../src/base/FundBase.sol";

contract ConcreteFundBase is FundBase {
    constructor(
		string memory name,
        string memory description,
        string memory imageUri,
        address initialOwner
	) FundBase(
		name, 
		description, 
		imageUri, 
		initialOwner
		) {}
}

contract Rejector {
    fallback() external payable {
        revert("Reject ETH");
    }

    function trigger(ConcreteFundBase fundBase, uint256 amount) external {
        fundBase.withdrawFunds(amount);
    }
}

contract FundBaseTest is Test {
    ConcreteFundBase public fundBase;
	address public owner;
	string constant NAME = "test-name";
    string constant DESCRIPTION = "test-description";
    string constant IMAGEURI = "test-image";

    uint256 max_user_id = 1;
    address public user = vm.addr(max_user_id);
    uint256 constant VALID_WITHDRAW_AMOUNT = 1;
    uint256 constant FUND_AMOUNT = 10;

    event Withdrawal(address indexed sender, uint256 amount);
    event Deposit(address indexed from, uint256 amount);

    modifier funded() {
        address randomGuy = uniqueUser();
        hoax(randomGuy, FUND_AMOUNT);
        fundBase.depositFunds{value: FUND_AMOUNT}();
        _;
    }

    function setUp() public {
        fundBase = new ConcreteFundBase(NAME, DESCRIPTION, IMAGEURI, msg.sender);
        owner = msg.sender;
        max_user_id = 2;
    }

    function uniqueUser() private returns (address) {
        max_user_id++;
        return (vm.addr(max_user_id));
    }

    //	WITHDRAWAL

    function invalidWithdrawalExpectedResults(
        address _user,
        uint256 inital_user_balance,
        uint256 initial_contract_balance
    ) private view {
        assertEq(_user.balance, inital_user_balance);
        assertEq(address(fundBase).balance, initial_contract_balance);
    }

    function testValidWithdrawal() public funded {
        uint256 initial_contract_balance = address(fundBase).balance;
        uint256 inital_user_balance = owner.balance;

        vm.expectEmit(true, false, false, false);
        emit Withdrawal(owner, VALID_WITHDRAW_AMOUNT);

        vm.prank(owner);
        fundBase.withdrawFunds(VALID_WITHDRAW_AMOUNT);

        assertEq(owner.balance, inital_user_balance + VALID_WITHDRAW_AMOUNT);
        assertEq(address(fundBase).balance, initial_contract_balance - VALID_WITHDRAW_AMOUNT);
    }

    function testInvalidWithdrawNotOwner() public funded {
        uint256 initial_contract_balance = address(fundBase).balance;
        uint256 inital_user_balance = user.balance;

        vm.prank(user);
        vm.expectRevert();
        fundBase.withdrawFunds(VALID_WITHDRAW_AMOUNT);
        invalidWithdrawalExpectedResults(user, inital_user_balance, initial_contract_balance);
    }

    function testInvalidWithdrawTooMuch() public funded {
        uint256 initial_contract_balance = address(fundBase).balance;
        uint256 inital_user_balance = owner.balance;

        vm.prank(owner);
        vm.expectRevert();
        fundBase.withdrawFunds(FUND_AMOUNT + 1);
        invalidWithdrawalExpectedResults(owner, inital_user_balance, initial_contract_balance);
    }

    function testInvalidWithdrawZero() public funded {
        uint256 initial_contract_balance = address(fundBase).balance;
        uint256 inital_user_balance = owner.balance;

        vm.prank(owner);
        vm.expectRevert();
        fundBase.withdrawFunds(0);
        invalidWithdrawalExpectedResults(owner, inital_user_balance, initial_contract_balance);
    }

    function testInvalidWithdrawUserRejects() public funded {
        uint256 initial_contract_balance = address(fundBase).balance;
        Rejector rejector = new Rejector();
        address ownerRejectsETH = address(rejector);
        uint256 inital_user_balance = ownerRejectsETH.balance;

        vm.prank(owner);
        fundBase.transferOwnership(ownerRejectsETH);

        vm.expectRevert();
        rejector.trigger(fundBase, VALID_WITHDRAW_AMOUNT);

        invalidWithdrawalExpectedResults(ownerRejectsETH, inital_user_balance, initial_contract_balance);
    }

    //FUNDING
    function testValidFunding() public {
        vm.deal(user, FUND_AMOUNT * 2);
        uint256 initial_user_balance = user.balance;
        uint256 initial_contract_balance = address(fundBase).balance;

        vm.expectEmit(true, false, false, false);
        emit Deposit(user, FUND_AMOUNT);

        vm.prank(user);
        fundBase.depositFunds{value: FUND_AMOUNT}();

        assertEq(address(fundBase).balance, initial_contract_balance + FUND_AMOUNT);
        assertEq(user.balance, initial_user_balance - FUND_AMOUNT);
    }
    // function testInvalidFundingTooLittle() public {

    // }
    function testInvalidFundingZero() public {
        vm.deal(user, FUND_AMOUNT * 2);
        uint256 initial_user_balance = user.balance;
        uint256 initial_contract_balance = address(fundBase).balance;

        vm.expectRevert();

        vm.prank(user);
        fundBase.depositFunds{value: 0}();

        assertEq(address(fundBase).balance, initial_contract_balance);
        assertEq(user.balance, initial_user_balance);
    }

    function testFallback() public {
        vm.deal(user, FUND_AMOUNT * 2);
        uint256 initial_user_balance = user.balance;
        uint256 initial_contract_balance = address(fundBase).balance;

        vm.expectEmit(true, false, false, false);
        emit Deposit(user, FUND_AMOUNT);

        vm.prank(user);
        (bool success,) = address(fundBase).call{value: FUND_AMOUNT}("Hello!");
        assertTrue(success);

        assertEq(address(fundBase).balance, initial_contract_balance + FUND_AMOUNT);
        assertEq(user.balance, initial_user_balance - FUND_AMOUNT);
    }

    function testReceive() public {
        vm.deal(user, FUND_AMOUNT * 2);
        uint256 initial_user_balance = user.balance;
        uint256 initial_contract_balance = address(fundBase).balance;

        vm.expectEmit(true, false, false, false);
        emit Deposit(user, FUND_AMOUNT);

        vm.prank(user);
        (bool success,) = address(fundBase).call{value: FUND_AMOUNT}("");
        assertTrue(success);

        assertEq(address(fundBase).balance, initial_contract_balance + FUND_AMOUNT);
        assertEq(user.balance, initial_user_balance - FUND_AMOUNT);
    }

//METADATA
	function testMetaData() public view {
		(string memory name, string memory description, string memory imageUri) = fundBase.metaData();
		assertEq(NAME, name);
		assertEq(DESCRIPTION, description);
		assertEq(IMAGEURI, imageUri);
	}

}
