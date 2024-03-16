// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.21;

import "../src/contracts/HUIToken.sol";
import {Test, console} from "forge-std/Test.sol";
import {HUIProvider} from "../src/contracts/HUIProvider.sol";
import {HUIVault} from "../src/contracts/HUIVault.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {NGU} from "./NGU.sol";

contract HUIVaultTest is Test {
    HUIToken hui;
    HUIProvider provider;
    HUIVault vault;
    ERC20 coin;

    address public player1 = 0x9c065bdc5a4a9e589Ae7DD555D66E99bb7E9ADe6;
    address public player2 = 0x4a8e79E5258592f208ddba8A8a0d3ffEB051B10A;

    function setUp() public {
        hoax(address(this));
        hui = new HUIToken();
        vm.startPrank(address(this));
        provider = new HUIProvider(address(hui));
        hui.setProvider(address(provider));
        vault = new HUIVault(address(hui), 1000, 1);
        vm.stopPrank();
        coin = new NGU();
    }

    function testPay() public {
        provider.expandUnderlyingTokens(address(coin));
        deal(address(coin), player1, 1000);
        deal(address(coin), player2, 1000);
        console.log("player1 balance", coin.balanceOf(player1));
        console.log("player2 balance", coin.balanceOf(player2));
        hoax(player1);
        coin.approve(address(provider), 1000);
        vm.prank(player1);
        provider.deposit(address(coin), 1000);
        hoax(player2);
        coin.approve(address(provider), 1000);
        vm.prank(player2);
        provider.deposit(address(coin), 1000);
        vm.startPrank(player1);
        hui.approve(address(vault), 100);
        vault.entryHui(1 days, 100);
        skip(1 days);
        hui.approve(address(vault), 100);
        vault.pay();
        vm.stopPrank();
        console.log("player1 balance", coin.balanceOf(player1));
    }
}
