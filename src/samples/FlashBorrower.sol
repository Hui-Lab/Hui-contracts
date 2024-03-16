// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.21;

import "../interfaces/IFlashBorrower.sol";

contract FlashBorrower is IFlashBorrower {
    bytes32 public constant CALLBACK_SUCCESS = keccak256("FlashBorrower.onFlashLoan");

    function onFlashLoan(address initiator, address token, uint256 amount, uint256 fee, bytes calldata data)
        external
        returns (bytes32)
    {
        return CALLBACK_SUCCESS;
    }
}
