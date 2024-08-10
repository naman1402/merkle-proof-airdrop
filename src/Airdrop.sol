// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import { MerkleProof } from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import { IERC20, SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { EIP712 } from "@openzeppelin/contracts/utils/cryptography/EIP712.sol";
import { SignatureChecker } from "@openzeppelin/contracts/utils/cryptography/SignatureChecker.sol";
import { ECDSA } from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import { MessageHashUtils } from "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";


/// @dev custom errors
error Airdrop__InvalidProof();
error Airdrop__AlreadyClaimed();
error Airdrop__InvalidSignature();

/// @title Merkle Airdrop - Airdrop tokens to users who can prove they are in merkle tree
contract Airdrop is EIP712{

    /// @dev Elliptic Curve Digital Signature Algorithm: functions are used to verify that a message was signed by the holder of the private keys of a given address
    /// @dev prevent sending token to address who can't receive using SafeERC20
    using ECDSA for bytes32;
    using SafeERC20 for IERC20;

    event Claimed(address account, uint256 amount);
    event MerkleRootUpdated(bytes32 newRoot);

    IERC20 private immutable airdropToken;
    bytes32 private immutable merkleRoot;
    mapping(address => bool) private hasClaimed;
    bytes32 private constant MESSAGE = keccak256("AirdropClaim(address account, uint256 amount)");

    struct AirdropClaim {
        address account;
        uint256 amount;
    }

    constructor(bytes32 _merkleRoot, IERC20 _airdropToken) EIP712("Merkle-Proof Airdrop", "1.0.0") {
        merkleRoot = _merkleRoot;
        airdropToken = _airdropToken;
    }

    ///////////////// FUNCTIONS 
    /// @dev verifies if claims is not made yet, validates the provided signature and merkle proof, and finally transfers the airdrop token
    /// @param v, r, s are ethereum ECDSA singature components

    function claim(address account, uint256 amount, bytes32[] calldata merkleProof, uint8 v, bytes32 r, bytes32 s) external {

        if (hasClaimed[account]) {
            revert Airdrop__AlreadyClaimed();
        }

        if(!isValidSignature(account, getMessageHash(account, amount), v, r, s)) {
            revert Airdrop__InvalidSignature();
        }

        // verifies calculated merkle leaf against merkle root using merkle proof
        bytes32 leaf = keccak256(bytes.concat(keccak256(abi.encode(account, amount))));
        if(MerkleProof.verify(merkleProof, merkleRoot, leaf)) {
            revert Airdrop__InvalidProof();
        }

        hasClaimed[account] = true;
        airdropToken.safeTransfer(account, amount);
    }

    // signed message we expect from user 
    /// @dev main objective is used to create hash of structured messageused for signing or verification purpose
    // 
    ///* @dev keccak256 is cryptographic hash used to create 256-bit hash of data 
    // abi.encode(); encode data into binary format suitable for eth transaction, 

    function getMessageHash(address account, uint256 amount) public view returns (bytes32) {
        return _hashTypedDataV4(keccak256(abi.encode(MESSAGE, AirdropClaim({ account: account, amount: amount}))));
    }

    /////////////////// VIEW FUNCTIONS
    function getAirdropToken() external view returns (IERC20) {
        return airdropToken;
    }

    function getMerkleRoot() external view returns (bytes32) {
        return merkleRoot;
    }

    function isValidSignature(address signer, bytes32 digest, uint8 _v, bytes32 _r, bytes32 _s) internal pure returns (bool) {
        (address actualSigner, /*ECDSA.RecoverError recoverError */, /*bytes32 signatureLength */) = ECDSA.tryRecover(digest, _v, _r, _s);
        return (actualSigner == signer);
    } 
}

