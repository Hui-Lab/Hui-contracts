// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.21;
import { console, Test } from "forge-std/Test.sol";
import { HUIToken } from "../src/HUIToken.sol";

contract TokenTest is Test {
    function setUp() public {
        HUIToken token = new HUIToken();
        console.log("Token address: %s", address(token));
    } 

    function testToken() public {
        HUIToken token = new HUIToken();
        console.log("Token name: %s", token.name());
        console.log("Token symbol: %s", token.symbol());
        console.log("Token decimals: %s", token.decimals());
    }
}