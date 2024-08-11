// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {console} from "forge-std/console.sol";
import {Token} from "../src/Token.sol";
import {Airdrop} from "../src/Airdrop.sol";
import {Deploy} from "../script/Deploy.s.sol";
import {ZkSyncChainChecker} from "foundry-devops/src/ZkSyncChainChecker.sol";

contract AirdropTest is Test, ZkSyncChainChecker {

    Airdrop airdrop;
    Token token;
    address gasPayer;
    address user;
    uint256 userPrivateKey;

    bytes32 root = 0xaa5d581231e596618465a56aa0f5870ba6e20785fe436d5bfb82b08662ccc7c4;
    uint256 amount = 25 * 1e18;
    uint256 amountToSend = amount * 5;

    bytes32 proofOne = 0x0fd7c981d39bece61f7499702bf59b3114a90e66b51ba2c53abdf7b62986c00a;
    bytes32 proofTwo = 0xe5ebd1e1b5a5478a944ecab36a9a954ac3b6b8216875f6524caa7a1d87096576;
    bytes32[] proof = [proofOne, proofTwo];

    function setUp() public {
        if(!isZkSyncChain()) {
            Deploy deployer = new Deploy();
            (airdrop, token) = deployer.deployAirdrop();
        } else {
            token = new Token();
            airdrop = new Airdrop(root, token);
            token.mint(token.owner(), amountToSend);
            token.transfer(address(airdrop), amountToSend);
        }

        gasPayer = makeAddr("gasPayer");
        (user, userPrivateKey) = makeAddrAndKey("user");
    }

    function signMessage(uint256 privateKey, address account) public view returns(uint8 v, bytes32 r, bytes32 s) {
        bytes32 hashedMessage = airdrop.getMessageHash(account, amount);
        (v, r, s) = vm.sign(privateKey, hashedMessage);
    }

    function testUsersCanClaim() public {}
}
