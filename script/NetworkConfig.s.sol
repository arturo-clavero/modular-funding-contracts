// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {Script} from "forge-std/Script.sol";
import {MockV3Aggregator} from "../test/mocks/MockV3Aggregator.sol";

contract NetworkConfig is Script {
    uint256 public chainId;
    uint256 public constant SEPOLIA_ID = 11155111;
    uint256 public constant ETHEREUM_ID = 1;
    address public constant SEPOLIA_PRICEFEED = address(0x694AA1769357215DE4FAC081bf1f309aDC325306);
    address public constant ETHEREUM_PRICEFEED = address(0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419);
    mapping(uint256 => address) public pricefeedMap;

    constructor() {
        pricefeedMap[SEPOLIA_ID] = SEPOLIA_PRICEFEED;
        pricefeedMap[ETHEREUM_ID] = ETHEREUM_PRICEFEED;
    }

    function getPriceFeed() external returns (address) {
        chainId = block.chainid;
        address priceFeed = pricefeedMap[chainId];
        if (priceFeed == address(0)) {
            priceFeed = deployMock();
        }
        return priceFeed;
    }

    function deployMock() private returns (address) {
        address priceFeed;
        //vm.startBroadcast();
        priceFeed = address(new MockV3Aggregator(8, 2000e8));
        //vm.stopBroadcast();
        pricefeedMap[block.chainid] = priceFeed;
        return priceFeed;
    }
}
