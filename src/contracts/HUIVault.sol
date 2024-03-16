// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.21;

import "./HUIToken.sol";
import "../interfaces/IFlashLender.sol";
import "../interfaces/IFlashBorrower.sol";
import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract HUIVault is IFlashLender, Ownable {
    using EnumerableSet for EnumerableSet.AddressSet;

    bytes32 public constant CALLBACK_SUCCESS = keccak256("FlashBorrower.onFlashLoan");
    uint256 public constant DECIMALS = 10000;
    uint256 public immutable feeProportion; //  1 == 0.01%.

    HUIToken public immutable hui;

    struct UserDetail {
        uint256 entryTime;
        uint256 period;
        uint256 amountPerPeriod;
        uint256 balance;
        uint256 currentPaymentTime;
        bool expired;
    }

    mapping(address user => UserDetail) public userDetails;
    EnumerableSet.AddressSet userEntry;

    uint256 public finalBalance = 0;
    uint256 public managerClaimable = 0;

    constructor(address _hui, uint256 _finalBalance, uint256 _feeProportion) Ownable(_msgSender()) {
        hui = HUIToken(_hui);
        finalBalance = _finalBalance;
        feeProportion = _feeProportion;
    }

    /** See IFlashLender */
    function flashLoan(IFlashBorrower receiver, uint256 amount, bytes calldata data) external returns (bool) {
        uint256 fee = flashFee(amount);
        require(hui.transfer(address(receiver), amount), "FlashLender: Transfer failed");
        require(
            receiver.onFlashLoan(msg.sender, address(hui), amount, fee, data) == CALLBACK_SUCCESS,
            "FlashLender: Callback failed"
        );
        require(hui.transferFrom(address(receiver), address(this), amount + fee), "FlashLender: Repay failed");
        return true;
    }

    /** See IFlashLender */
    function flashFee(uint256 amount) public view returns (uint256) {
        return amount * feeProportion / 10000;
    }

    /** See IFlashLender */
    function maxFlashLoan() external view returns (uint256) {
        return hui.balanceOf(address(this));
    }

    function getNumberOfCompletedUser() public view returns (uint256) {
        uint256 Count = 0;
        for (uint256 i = 0; i < userEntry.length(); ++i) {
            if (userDetails[userEntry.at(i)].balance < finalBalance) continue;
            ++Count;
        }
        return Count;
    }

    function managerClaim() public onlyOwner() {
        hui.transfer(owner(), managerClaimable);
    }

    function distribute(address expiredUser) internal {
        if (userEntry.length() == 0) return;
        uint256 value = userDetails[expiredUser].balance;
        uint256 numberCompletedUserInVault = getNumberOfCompletedUser();
        if (numberCompletedUserInVault == 0) {
            managerClaimable += value;
            return;
        }
        uint256 userClaimable = value / (numberCompletedUserInVault * 2);
        for (uint256 i = 0; i < userEntry.length(); ++i) {
            if (userDetails[userEntry.at(i)].balance < finalBalance) continue;
            userDetails[userEntry.at(i)].balance += userClaimable;
        }
        uint256 remain = value - userClaimable * numberCompletedUserInVault;
        managerClaimable += remain;
    }

    function updateUser(address user) public {
        if (userEntry.contains(user) == false) return;
        if (block.timestamp > getNextPaymentTime() && userDetails[user].balance < finalBalance) {
            require(userDetails[user].expired == false);
            userDetails[user].expired = true;
        }
        if (userDetails[user].expired == true) {
            distribute(user);
            delete userDetails[user];
            userEntry.remove(user);
        }
    }

    function updateAllUsers() public {
        for (uint256 i = 0; i < userEntry.length(); ++i) {
            updateUser(userEntry.at(i));
        }
    }

    function maximumPeriod() public pure returns (uint256) {
        return 365 days;
    }

    function minimumPeriod() public pure returns (uint256) {
        return 1 days;
    }

    function getNextPaymentTime() public view returns (uint256) {
        return userDetails[msg.sender].entryTime
            + userDetails[msg.sender].currentPaymentTime * userDetails[msg.sender].period;
    }

    function getAmountNeedToPay() public view returns (uint256) {
        return (userDetails[msg.sender].currentPaymentTime + 1) * userDetails[msg.sender].amountPerPeriod;
    }

    function entryHui(uint256 period, uint256 amountPerPeriod) public {
        updateUser(msg.sender);
        require(period <= maximumPeriod() && period >= minimumPeriod(), "Period must be between 1 day and 365 days");
        require(period % 1 days == 0, "Period must be a multiple of 1 day");
        require(
            amountPerPeriod > 0 && amountPerPeriod <= hui.balanceOf(msg.sender),
            "amountPerPeriod must be greater than 0 and less than or equal to the balance of the user"
        );
        require(
            amountPerPeriod * period >= finalBalance, "amountPerPeriod * period must be greater than or equal to finalBalance"
        );
        require(userEntry.contains(msg.sender) == false, "User should pay, not entry");
        hui.transferFrom(msg.sender, address(this), amountPerPeriod);
        userDetails[msg.sender] = UserDetail({
            entryTime: block.timestamp,
            period: period,
            amountPerPeriod: amountPerPeriod,
            balance: amountPerPeriod,
            currentPaymentTime: 1,
            expired: false
        });
        userEntry.add(msg.sender);
    }

    function pay() public {
        updateUser(msg.sender);
        require(userDetails[msg.sender].balance < finalBalance, "You pay total fee needed");
        require(userEntry.contains(msg.sender) == true, "User should entry, not pay");
        hui.transferFrom(msg.sender, address(this), userDetails[msg.sender].amountPerPeriod);
        userDetails[msg.sender].balance += userDetails[msg.sender].amountPerPeriod;
        userDetails[msg.sender].currentPaymentTime++;
    }

    function withdraw() public {
        updateUser(msg.sender);
        require(userDetails[msg.sender].balance >= finalBalance, "You should pay all fee needed");
        require(userEntry.contains(msg.sender) == true, "User should entry, not withdraw");
        hui.transfer(msg.sender, userDetails[msg.sender].balance);
        delete userDetails[msg.sender];
        userEntry.remove(msg.sender);
    }

    function getRewardAndWithdraw() public {
        updateUser(msg.sender);
        require(userDetails[msg.sender].balance >= finalBalance, "You should pay all fee needed");
        require(userEntry.contains(msg.sender) == true, "User should entry, not withdraw");
        updateAllUsers();
        hui.transfer(msg.sender, userDetails[msg.sender].balance);
        delete userDetails[msg.sender];
        userEntry.remove(msg.sender);
    }
}
