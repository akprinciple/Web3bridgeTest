// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

abstract contract Transactions{
     mapping(uint256 => Transaction) public transactions;
     uint256 public txCount;
    // bytes32 public merkleRoot;
    uint256 public constant TIMELOCK_DURATION = 1 hours;
    event Confirmation(uint256 indexed txId, address indexed owner);
    event Execution(uint256 indexed txId);

    event Submission(uint256 indexed txId);
    bool public paused;
    struct Transaction {
        address to;
        uint256 value;
        bytes data;
        bool executed;
        uint256 confirmations;
        uint256 submissionTime;
        uint256 executionTime;
    }
    uint256 public threshold;
    mapping(uint256 => mapping(address => bool)) public confirmed;
    mapping(address => bool) public isOwner;

    function submitTransaction(address to, uint256 value, bytes calldata data) external {
        require(!paused, "paused");
        require(isOwner[msg.sender]);
        uint256 id = txCount++;
        transactions[id] = Transaction({
            to: to,
            value: value,
            data: data,
            executed: false,
            confirmations: 1,
            submissionTime: block.timestamp,
            executionTime: 0
        });
        confirmed[id][msg.sender] = true;
        emit Submission(id);
    }

    function confirmTransaction(uint256 txId) external {
        require(!paused, "paused");
        require(isOwner[msg.sender]);
        Transaction storage txn = transactions[txId];
        require(!txn.executed);
        require(!confirmed[txId][msg.sender]);
        confirmed[txId][msg.sender] = true;
        txn.confirmations++;
        if (txn.confirmations >= threshold && txn.executionTime == 0) {
            txn.executionTime = block.timestamp + TIMELOCK_DURATION;
        }
        emit Confirmation(txId, msg.sender);
    }

    function executeTransaction(uint256 txId) external {
        Transaction storage txn = transactions[txId];
        require(txn.confirmations >= threshold);
        require(!txn.executed);
        require(block.timestamp >= txn.executionTime);
        txn.executed = true;
        (bool s,) = txn.to.call{value: txn.value}(txn.data);
        require(s);
        emit Execution(txId);
    }
}