// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import {Token} from "../src/Token.sol";
import {Airdrop, IERC20} from "../src/Airdrop.sol";
import {console} from "forge-std/console.sol";
import {Script} from "forge-std/Script.sol";

contract Deploy is Script {

    bytes32 public ROOT = 0xaa5d581231e596618465a56aa0f5870ba6e20785fe436d5bfb82b08662ccc7c4;
    uint256 public AMOUNT = 5 * (25 * 1e18); // 5 users, 25 tokens each
    function deployAirdrop() public returns (Airdrop, Token) {

        vm.startBroadcast();
        Token token = new Token();
        Airdrop airdrop = new Airdrop(ROOT, IERC20(token));
        token.mint(token.owner(), AMOUNT);
        IERC20(token).transfer(address(airdrop), AMOUNT);
        vm.stopBroadcast();
        return (airdrop, token);
    }

    function run() external returns (Airdrop, Token) {
        return deployAirdrop();
    }
}
