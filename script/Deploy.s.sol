// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {console, Script} from "forge-std/Script.sol";
import "../src/contracts/HUIToken.sol";
import "../src/contracts/HUIProvider.sol";

contract Deploy is Script {
    function setUp() public {
        uint256 private_key = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(private_key);
        console.log("Deploying Token contract...");
        // HUIToken token = new HUIToken();
        // HUIProvider provider = new HUIProvider(address(token));
        // provider.expandUnderlyingTokens(address(0x1990BC6dfe2ef605Bfc08f5A23564dB75642Ad73));
        // provider.expandUnderlyingTokens(address(0xf56dc6695cF1f5c364eDEbC7Dc7077ac9B586068));
        // provider.expandUnderlyingTokens(address(0x8741Ba6225A6BF91f9D73531A98A89807857a2B3));
        // provider.expandUnderlyingTokens(address(0x4Ef6081357fC5546f88AcEf559FF4335F03a88Be));
        HUIToken token = HUIToken(0x69058990c352aEcC7b7aeaC741e7172733D875aB);
        HUIProvider provider = HUIProvider(0x0aa186C309bAFC6303a6128558BaB409B8E586EF);
        token.setProvider(address(provider));
        console.log("Token address: %s", address(token));
        console.log("Provider address: %s", address(provider));
        vm.stopBroadcast();
    }

    function run() public {}
}
