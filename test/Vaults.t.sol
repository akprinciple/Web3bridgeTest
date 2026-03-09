// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/Vaults.sol";

contract VaultsTest is Test {
    EvictionVault public vault;
    address[] public owners;
    address public user1 = address(0xdead);
    address public user2 = address(0xbeef);
    address public user3 = address(0xcafe);

    function setUp() public {
        
        owners.push(address(this));
        owners.push(user1);
        owners.push(user2);
        owners.push(user3);
        vault = new EvictionVault(owners, 3);

        vm.deal(user1, 1 ether);
        vm.deal(user2, 2 ether);
        vm.deal(user3, 3 ether);
    }

    function testDeposit() public {
        vm.startPrank(user1);
        uint256 amount = 0.3 ether;
        
        assertEq(vault.balances(user1), 0.3);
        
        
        vault.deposit{value: amount}();
        
        // Verify state changes
        assertEq(vault.balances(user1), amount);
        assertEq(vault.totalVaultValue(), amount);
        assertEq(address(vault).balance, amount);
        
        vm.stopPrank();
    }

    function testReceive() public {
        vm.startPrank(user1);
        uint256 amount = 5 ether;

        // Send ETH directly to contract (triggers receive())
        (bool success, ) = address(vault).call{value: amount}("");
        assertTrue(success, "Transfer failed");

        // Verify state changes
        assertEq(vault.balances(user1), amount);
        assertEq(vault.totalVaultValue(), amount);
        
        vm.stopPrank();
    }

    function testWithdraw() public {
        vm.startPrank(user1);
        uint256 depositAmount = 10 ether;
        vault.deposit{value: depositAmount}();
        
        uint256 withdrawAmount = 5 ether;
        uint256 balanceBefore = user1.balance;
        
        // Withdraw
        vault.withdraw(withdrawAmount);
        
        // Verify state changes
        assertEq(vault.balances(user1), depositAmount - withdrawAmount);
        assertEq(vault.totalVaultValue(), depositAmount - withdrawAmount);
        assertEq(user1.balance, balanceBefore + withdrawAmount);
        
        vm.stopPrank();
    }

    function testWithdrawInsufficientBalance() public {
        vm.startPrank(user1);
        vault.deposit{value: 1 ether}();
        
        // Try to withdraw more than balance
        vm.expectRevert(); 
        vault.withdraw(2 ether);
        
        vm.stopPrank();
    }

    function testPauseUnpause() public {
        // Only owner can pause (address(this) is an owner)
        vault.pause();
        assertTrue(vault.paused());

        vm.startPrank(user1);
        // Deposits should still work while paused (based on Deposits.sol logic)
        vault.deposit{value: 1 ether}();
        
        // Withdraw should fail when paused
        vm.expectRevert("paused");
        vault.withdraw(1 ether);
        vm.stopPrank();

        // Unpause
        vault.unpause();
        assertFalse(vault.paused());

        // Withdraw should succeed now
        vm.startPrank(user1);
        vault.withdraw(1 ether);
        assertEq(vault.balances(user1), 0);
        vm.stopPrank();
    }
}