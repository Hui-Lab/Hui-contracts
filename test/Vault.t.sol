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
        provider.expandUnderlyingTokens(address(coin));
        vm.stopPrank();
    }

    function testPay() public {
        deal(address(coin), player1, 1000);
        deal(address(coin), player2, 2000);
        //
        hoax(player1);
        coin.approve(address(provider), 1000);
        hoax(player1);
        provider.deposit(address(coin), 1000);
        hoax(player2);
        coin.approve(address(provider), 1000);
        hoax(player2);
        provider.deposit(address(coin), 1000);
        //
        vm.startPrank(player1);
        hui.approve(address(vault), 100);
        vault.entryHui(1 days, 100);
        for (uint256 i = 0; i < 9; ++i) {
            skip(1 days);
            hui.approve(address(vault), 100);
            vault.pay(100);
        }
        vm.stopPrank();
        vm.startPrank(player2);
        hui.approve(address(vault), 100);
        vault.entryHui(1 days, 100);
        for (uint256 i = 0; i < 8; ++i) {
            skip(1 days);
            hui.approve(address(vault), 100);
            vault.pay(100);
        }
        vm.stopPrank();
        skip(1 days + 1);
        assertEq(hui.balanceOf(player1), 0);
        assertEq(hui.balanceOf(player2), 100);
        assertEq(vault.isExpired(player2), true);
    }

    function testWithdraw() public {
        testPay();
        try vault.withdraw() {
            assert(false);
        } catch Error(string memory reason) {
            assertEq(reason, "User should entry, not withdraw");
        }
        hoax(player2);
        try vault.withdraw() {
            assert(false);
        } catch Error(string memory reason) {
            assertEq(reason, "You should pay all fee needed or entry again");
        }

        hoax(player1);
        vault.withdraw();
        assertEq(hui.balanceOf(player1), 1000);
    }

    function testWithdrawWithReward() public {
        testPay();
        try vault.getRewardAndWithdraw() {
            assert(false);
        } catch Error(string memory reason) {
            assertEq(reason, "User should entry, not withdraw");
        }
        hoax(player2);
        try vault.getRewardAndWithdraw() {
            assert(false);
        } catch Error(string memory reason) {
            assertEq(reason, "You should pay all fee needed or entry again");
        }

        hoax(player1);
        vault.getRewardAndWithdraw();
        assertEq(hui.balanceOf(player1), 1450);
    }

    function testEntry() public {
        testWithdraw();
        vm.startPrank(player2);
        coin.approve(address(provider), 1000);
        provider.deposit(address(coin), 1000);
        hui.approve(address(vault), 50);
        vault.entryHui(3 days, 50);
        for (uint256 i = 0; i < 19; ++i) {
            skip(3 days);
            hui.approve(address(vault), 50);
            vault.pay(50);
        }
        vault.withdraw();
        vm.stopPrank();
    }
}
