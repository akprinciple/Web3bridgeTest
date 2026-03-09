// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract EvictionVault {

    

    address[] public owners;
    mapping(address => bool) public isOwner;

    uint256 public threshold;

    mapping(uint256 => mapping(address => bool)) public confirmed;
   

    

    mapping(address => bool) public claimed;

    mapping(bytes32 => bool) public usedHashes;

    uint256 public constant TIMELOCK_DURATION = 1 hours;

    

    bool public paused;

    event Submission(uint256 indexed txId);
    event Confirmation(uint256 indexed txId, address indexed owner);
    event Execution(uint256 indexed txId);
    event MerkleRootSet(bytes32 indexed newRoot);
    event Claim(address indexed claimant, uint256 amount);

    constructor(address[] memory _owners, uint256 _threshold) payable {
        require(_owners.length > 0, "no owners");
        threshold = _threshold;

        for (uint i = 0; i < _owners.length; i++) {
            address o = _owners[i];
            require(o != address(0));
            isOwner[o] = true;
            owners.push(o);
        }
        totalVaultValue = msg.value;
    }

    

    
    

    function setMerkleRoot(bytes32 root) external {
        merkleRoot = root;
        emit MerkleRootSet(root);
    }

    function claim(bytes32[] calldata proof, uint256 amount) external {
        require(!paused);
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender, amount));
        bytes32 computed = MerkleProof.processProof(proof, leaf);
        require(computed == merkleRoot);
        require(!claimed[msg.sender]);
        claimed[msg.sender] = true;
        payable(msg.sender).transfer(amount);
        totalVaultValue -= amount;
        emit Claim(msg.sender, amount);
    }

    function verifySignature(
        address signer,
        bytes32 messageHash,
        bytes memory signature
    ) external pure returns (bool) {
        return MerkleProof.recover(messageHash, signature) == signer;
    }

    
}