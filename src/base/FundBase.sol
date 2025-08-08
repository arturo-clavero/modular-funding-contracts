// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "../utils/FundErrors.sol";
import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";
import {PriceConverter} from "../libs/PriceConverter.sol";
import {BlockRateLimiter} from "../libs/BlockRateLimiter.sol";

/// @dev Includes metadata, minimum deposit handling, price feed integration, and block rate-limiting
abstract contract FundBase is ReentrancyGuard, Ownable {
    /// @notice: Fund metadata such as name and description
    struct MetaData {
        string name;
        string description;
    }

    MetaData public metaData;
    uint256 public minDeposit;
    address public priceFeedUSD;
    BlockRateLimiter.LimitData internal blockRate;

    using PriceConverter for uint256;
    using BlockRateLimiter for BlockRateLimiter.LimitData;

    event Deposit(address indexed from, uint256 amount);
    event Withdrawal(address indexed to, uint256 amount);

    /// @param name Name of the fund
    /// @param description Description of the fund
    /// @param _priceFeedUSD Address of the Chainlink USD price feed
    constructor(string memory name, string memory description, address _priceFeedUSD) Ownable(msg.sender) {
        priceFeedUSD = _priceFeedUSD;
        metaData = MetaData(name, description);
    }

    /// @dev Routes plain transfers directly into `depositFunds`
    receive() external payable virtual {
        depositFunds();
    }

    /// @dev Calls `depositFunds` when value is sent to non-existent function
    fallback() external payable virtual {
        depositFunds();
    }

    /// @dev Converts the amount to wei using the Chainlink price feed
    /// @param amount The fiat amount (e.g. 50 = $50)
    /// @param currency The currency symbol, e.g., "USD"
    function setMinDeposit(uint256 amount, string calldata currency) public onlyOwner {
        minDeposit = PriceConverter.getRates(amount, currency, priceFeedUSD);
    }

    /// @param limit Number of blocks between allowed withdrawals
    function setWithdrawalBlockLimit(uint256 limit) external {
        blockRate.setLimit(limit);
    }

    /// @return Number of blocks between allowed withdrawals
    function getWithdrawalBlockLimit() external view returns (uint256) {
        return blockRate.getLimit();
    }

    /// @dev Only callable by the contract owner and rate-limited via blockRate
    /// @param amount Amount to withdraw in wei
    function withdrawFunds(uint256 amount) public virtual onlyOwner {
        if (address(this).balance < amount || amount == 0) {
            revert InsufficientFunds();
        }
        blockRate.secureWithdrawal(msg.sender);
        _sendEth(amount);
        emit Withdrawal(msg.sender, amount);
    }

    /// @dev Requires value to meet `minDeposit` requirement
    function depositFunds() public payable virtual {
        if (msg.value == 0 || msg.value < minDeposit) {
            revert InsufficientDeposit();
        }
        emit Deposit(msg.sender, msg.value);
    }

    /// @dev Uses low-level call to avoid gas stipend issues; protected by `nonReentrant`
    /// @param amount Amount to send in wei
    function _sendEth(uint256 amount) internal nonReentrant {
        (bool success,) = payable(msg.sender).call{value: amount}("");
        if (!success) revert TransferFailed();
    }
}
