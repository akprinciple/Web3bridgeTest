// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/Vaults.sol";

contract VaultsTest is Test {
    EvictionVault public vault;
    address[] public owners;
    address public user1 = address(0xdead);
    address public user2 = address(0xbeef);

    function setUp() public {
        // Setup owners
        owners.push(address(this));
        owners.push(user1);
        owners.push(user2);
        vault = new EvictionVault(owners, 2);

        // Fund users
        vm.deal(user1, 1 ether);
        vm.deal(user2, 2 ether);
    }

    function testDeposit() public {
        vm.startPrank(user1);
        uint256 amount = 0.3 ether;
        
        // Check initial state
        assertEq(vault.balances(user1), 0);
        
            vault.deposit{value: amount}();
        
        assertEq(vault.balances(user1), amount);
        assertEq(vault.totalVaultValue(), amount);
        vm.stopPrank();
    }

    function testWithdraw() public {
        vm.startPrank(user1);
        uint256 depositAmount = 0.5 ether;
        vault.deposit{value: depositAmount}();

        uint256 withdrawAmount = 0.2 ether;
        uint256 balanceBefore = user1.balance;

        vault.withdraw(withdrawAmount);

        assertEq(vault.balances(user1), depositAmount - withdrawAmount);
        assertEq(vault.totalVaultValue(), depositAmount - withdrawAmount);
        
        vm.stopPrank();
    }
}