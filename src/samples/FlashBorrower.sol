// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.21;

import "../interfaces/IFlashBorrower.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {HUIProvider} from "../contracts/HUIProvider.sol";

contract FlashBorrower is IFlashBorrower {
    bytes32 public constant CALLBACK_SUCCESS = keccak256("FlashBorrower.onFlashLoan");
    HUIProvider public provider;
    IERC20 public underlyingToken;

    constructor(address _provider, address _underlyingToken) {
        provider = HUIProvider(_provider);
        underlyingToken = IERC20(_underlyingToken);
    }

    /*
        see {IFlashBorrower-onFlashLoan}
    */
    function onFlashLoan(address initiator, address token, uint256 amount, uint256 fee, bytes calldata data)
        external
        virtual
        returns (bytes32)
    {
        // IERC20 asset = IERC20(token);
        provider.withdraw(address(underlyingToken), amount);
        underlyingToken.approve(address(provider), amount + fee);
        provider.deposit(address(underlyingToken), amount + fee);
        return CALLBACK_SUCCESS;
    }
}
