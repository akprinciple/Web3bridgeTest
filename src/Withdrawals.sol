// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

//Ownable in openzeppelin
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "./Transactions.sol";
import "./Deposits.sol";

abstract contract Withdrawals is Ownable, ReentrancyGuard, Transactions, Deposits {
    event Withdrawal(address indexed withdrawer, uint256 amount);

    function withdraw(uint256 amount) external nonReentrant {
        require(!paused, "paused");
        require(balances[msg.sender] >= amount);
        balances[msg.sender] -= amount;
        totalVaultValue -= amount;
        payable(msg.sender).call{value: amount}('');
        emit Withdrawal(msg.sender, amount);
    }

    function emergencyWithdrawAll() external onlyOwner {
        payable(msg.sender).call{value: address(this).balance}('');
        totalVaultValue = 0;
    }

    function pause() external {
        require(isOwner[msg.sender]);
        paused = true;
    }

    function unpause() external {
        require(isOwner[msg.sender]);
        paused = false;
    }

}