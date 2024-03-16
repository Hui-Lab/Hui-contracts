// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.21;

import "./IFlashBorrower.sol";

interface IFlashLender {
    /**
     * @dev Loan `amount` tokens to `receiver`, and takes it back plus a `flashFee` after the callback.
     * @param receiver The contract receiving the tokens, needs to implement the `onFlashLoan(address user, uint256 amount, uint256 fee, bytes calldata)` interface.
     * @param amount The amount of tokens lent.
     * @param data A data parameter to be passed on to the `receiver` for any custom use.
     */
    function flashLoan(IFlashBorrower receiver, uint256 amount, bytes calldata data) external returns (bool);

    /**
     * @dev The fee to be charged for a given loan.
     * @param amount The amount of tokens lent.
     * @return The amount of `token` to be charged for the loan, on top of the returned principal.
     */
    function flashFee(uint256 amount) external view returns (uint256);

    /**
     * @dev The amount of currency available to be lent.
     * @return The amount of `token` that can be borrowed.
     */
    function maxFlashLoan() external view returns (uint256);
}
