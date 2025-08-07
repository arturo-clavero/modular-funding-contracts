//SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "../../src/utils/FundErrors.sol";
import {Test, console} from "forge-std/Test.sol";
import {Vault} from "../../src/modules/Vault.sol";
import {VaultDeploy} from "../../script/VaultDeploy.s.sol";
import {FundConstants} from "../utils/FundConstants.sol";

contract VaultTest is Test {
    Vault public vault;
    address public owner;
    uint256 public amount = 2;

    function setUp() public {
        VaultDeploy vaultDeploy = new VaultDeploy();
        vault = vaultDeploy.run();
        owner = address(msg.sender);
    }

    function depositVaultToSelf(address self, uint256 funds) private {
        vm.startPrank(self);
        uint256 vaultPrevBalance = address(vault).balance;
        uint256 selfPrevBalance = vault.getMyBalance();
        vm.deal(self, 10);
        vault.depositFunds{value: funds}();
        assertEq(vaultPrevBalance + funds, address(vault).balance);
        assertEq(selfPrevBalance + funds, vault.getMyBalance());
        vm.stopPrank();
    }

    function depositVaultToRecipient(address funder, address recipient, uint256 funds) private {
        vm.prank(recipient);
        uint256 recipientPrevBalance = vault.getMyBalance();
        vm.startPrank(funder);
        uint256 vaultPrevBalance = address(vault).balance;
        uint256 funderPrevBalance = vault.getMyBalance();
        vm.deal(funder, 10);
        vault.depositFundsTo{value: funds}(recipient);
        assertEq(vaultPrevBalance + funds, address(vault).balance);
        assertEq(funderPrevBalance, vault.getMyBalance());
        vm.stopPrank();
        vm.prank(recipient);
        assertEq(recipientPrevBalance + funds, vault.getMyBalance());
    }

    function testDepositVault() public {
        depositVaultToSelf(vm.addr(1), amount);
    }

    function testDepositVaultTo() public {
        depositVaultToRecipient(vm.addr(1), vm.addr(2), amount);
    }

    function testWithdrawalSelfFund() public {
        address user = vm.addr(1);
        depositVaultToSelf(user, amount);
        uint256 prevBalanceVault = address(vault).balance;
        vm.deal(user, 0);
        vm.startPrank(user);
        vault.withdrawFunds(amount);
        assertEq(prevBalanceVault - amount, address(vault).balance);
        assertEq(user.balance, amount);
    }

    function testWithdrawalMultipleSelfFund() public {
        address user = vm.addr(1);
        depositVaultToSelf(user, amount);
        depositVaultToSelf(user, amount);
        uint256 prevBalanceVault = address(vault).balance;
        uint256 withdrawalAmount = amount * 2;
        vm.startPrank(user);
        vm.deal(user, 0);
        vault.withdrawFunds(withdrawalAmount);
        assertEq(prevBalanceVault - withdrawalAmount, address(vault).balance);
        assertEq(user.balance, withdrawalAmount);
    }

    function testWithdrawalSelfFundZeroAmount() public {
        address user = vm.addr(1);
        depositVaultToSelf(user, amount);
        uint256 prevBalanceVault = address(vault).balance;
        vm.startPrank(user);
        vm.deal(user, 0);
        vm.expectRevert();
        vault.withdrawFunds(0);
        assertEq(prevBalanceVault, address(vault).balance);
        assertEq(user.balance, 0);
    }

    function testWithdrawalNoDeposit() public {
        address user = vm.addr(1);
        uint256 prevBalanceVault = address(vault).balance;
        vm.startPrank(user);
        vm.deal(user, 0);
        vm.expectRevert();
        vault.withdrawFunds(amount);
        assertEq(prevBalanceVault, address(vault).balance);
        assertEq(user.balance, 0);
    }

    function testWithdrawalWrongRecipient() public {
        address user = vm.addr(1);
        address recipient = vm.addr(2);
        depositVaultToRecipient(user, recipient, amount);
        uint256 prevBalanceVault = address(vault).balance;
        vm.startPrank(user);
        vm.deal(user, 0);
        vm.expectRevert();
        vault.withdrawFunds(amount);
        assertEq(prevBalanceVault, address(vault).balance);
        assertEq(user.balance, 0);
    }

    function testWithdrawalTooMuch() public {
        address user = vm.addr(1);
        depositVaultToSelf(user, amount);
        uint256 withdrawalAmount = amount * 2;
        uint256 prevBalanceVault = address(vault).balance;
        vm.startPrank(user);
        vm.deal(user, 0);
        vm.expectRevert();
        vault.withdrawFunds(withdrawalAmount);
        assertEq(prevBalanceVault, address(vault).balance);
        assertEq(user.balance, 0);
    }

    function testAllWithdrawal() public {
        address user = vm.addr(1);
        depositVaultToSelf(user, amount);
        hoax(user, 0);
        vault.withdrawAllFunds();
        assertEq(0, address(vault).balance);
        assertEq(user.balance, amount);
        vm.stopPrank();
    }

    function testAllWithdrawalMultipleFunds() public {
        address user = vm.addr(1);
        address userB = vm.addr(2);
        depositVaultToSelf(user, amount);
        depositVaultToSelf(userB, amount);
        depositVaultToSelf(user, amount);
        hoax(user, 0);
        vault.withdrawAllFunds();
        assertEq(amount, address(vault).balance);
        assertEq(user.balance, amount * 2);
    }

    function testFallback() public {
        address user = vm.addr(1);
        uint256 prevBalance = address(vault).balance;
        vm.deal(user, amount);
        vm.startPrank(user);
        address(vault).call{value: amount}("");
        assertEq(prevBalance + amount, address(vault).balance);
        assertEq(vault.getMyBalance(), amount);
        vm.stopPrank();
    }

    function testFallbackUserParameter() public {
        address funder = vm.addr(1);
        address recipient = vm.addr(2);
        uint256 prevBalance = address(vault).balance;
        hoax(funder, amount);
        address(vault).call{value: amount}(abi.encode(recipient));
        assertEq(prevBalance + amount, address(vault).balance);
        vm.prank(recipient);
        assertEq(vault.getMyBalance(), amount);
    }
}
