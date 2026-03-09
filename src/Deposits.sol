// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

abstract contract Deposits{

    mapping(address => uint256) public balances;
    uint256 public totalVaultValue;
     event Deposit(address indexed depositor, uint256 amount);

     receive() external payable {
        balances[msg.sender] += msg.value;
        totalVaultValue += msg.value;
        emit Deposit(msg.sender, msg.value);
    }

    function deposit() external payable {
        balances[msg.sender] += msg.value;
        totalVaultValue += msg.value;
        emit Deposit(msg.sender, msg.value);
    }
}