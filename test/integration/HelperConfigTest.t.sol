// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import {Test, console} from "forge-std/Test.sol";
import {HelperConfig, Constants} from "script/HelperConfig.s.sol";

contract HelperConfigTest is Test, Constants {
    HelperConfig helperConfig;
    uint256 raffleFee;
    uint256 interval;
    address vrfCoordinator;
    bytes32 keyHash;
    uint256 subscriptionId;
    uint32 callbackGasLimit;
    address link;

    function setUp() public {
        helperConfig = new HelperConfig();
        (raffleFee, interval, vrfCoordinator, keyHash, subscriptionId, callbackGasLimit, link,) =
            (helperConfig.activeNetworkConfig());
    }

    /*//////////////////////////////////////////////////
               ActiveNetworkConfig Test
    //////////////////////////////////////////////////*/

    function testActiveNetworkConfigIsSetToGetOrCreateAnvilConfigWhenOnAnvil() public {
        // Arrange
        HelperConfig.NetworkConfig memory expectedConfig = helperConfig.getOrCreateAnvilConfig();
        // Act, Assert
        assert(raffleFee == expectedConfig.raffleFee);
        assert(interval == expectedConfig.interval);
        assert(vrfCoordinator != address(0));
        assert(keyHash == expectedConfig.keyHash);
        assert(subscriptionId == expectedConfig.subscriptionId);
        assert(callbackGasLimit == expectedConfig.callbackGasLimit);
        assert(link != address(0));
    }

    /*//////////////////////////////////////////////////
               GetETH-MainnetNetwork Test
    //////////////////////////////////////////////////*/

    function testEthMainnetChainIdGetsCorrectDetails() public {
        // Arrange
        uint256 chainId = ETH_MAINNET_CHAIN_ID;
        HelperConfig.NetworkConfig memory expectedConfig = helperConfig.getEthMainnetConfig();
        HelperConfig.NetworkConfig memory activeTestNetworkConfig = helperConfig.getNetworkConfigByChainId(chainId);
        // Act, Assert
        assert(activeTestNetworkConfig.raffleFee == expectedConfig.raffleFee);
        assert(activeTestNetworkConfig.interval == expectedConfig.interval);
        assert(activeTestNetworkConfig.vrfCoordinator == expectedConfig.vrfCoordinator);
        assert(activeTestNetworkConfig.keyHash == expectedConfig.keyHash);
        assert(activeTestNetworkConfig.subscriptionId == expectedConfig.subscriptionId);
        assert(activeTestNetworkConfig.callbackGasLimit == expectedConfig.callbackGasLimit);
        assert(activeTestNetworkConfig.link == expectedConfig.link);
    }

    /*//////////////////////////////////////////////////
               GetSepoliaNetwork Test
    //////////////////////////////////////////////////*/

    function testSepoliaChainIdGetsCorrectDetails() public {
        // Arrange
        uint256 chainId = SEPOLIA_CHAIN_ID;
        HelperConfig.NetworkConfig memory expectedConfig = helperConfig.getSepoliaConfig();
        HelperConfig.NetworkConfig memory activeTestNetworkConfig = helperConfig.getNetworkConfigByChainId(chainId);
        // Act, Assert
        assert(activeTestNetworkConfig.raffleFee == expectedConfig.raffleFee);
        assert(activeTestNetworkConfig.interval == expectedConfig.interval);
        assert(activeTestNetworkConfig.vrfCoordinator == expectedConfig.vrfCoordinator);
        assert(activeTestNetworkConfig.keyHash == expectedConfig.keyHash);
        assert(activeTestNetworkConfig.subscriptionId == expectedConfig.subscriptionId);
        assert(activeTestNetworkConfig.callbackGasLimit == expectedConfig.callbackGasLimit);
        assert(activeTestNetworkConfig.link == expectedConfig.link);
    }

    /*//////////////////////////////////////////////////
               GetAnvilNetwork Test
    //////////////////////////////////////////////////*/

    function testAnvilChainIdGetsCorrectDetails() public {
        // Arrange
        uint256 chainId = ANVIL_CHAIN_ID;
        HelperConfig.NetworkConfig memory expectedConfig = helperConfig.getOrCreateAnvilConfig();
        HelperConfig.NetworkConfig memory activeTestNetworkConfig = helperConfig.getNetworkConfigByChainId(chainId);
        // Act, Assert
        assert(activeTestNetworkConfig.raffleFee == expectedConfig.raffleFee);
        assert(activeTestNetworkConfig.interval == expectedConfig.interval);
        assert(activeTestNetworkConfig.vrfCoordinator != address(0));
        assert(activeTestNetworkConfig.keyHash == expectedConfig.keyHash);
        assert(activeTestNetworkConfig.subscriptionId == expectedConfig.subscriptionId);
        assert(activeTestNetworkConfig.callbackGasLimit == expectedConfig.callbackGasLimit);
        assert(activeTestNetworkConfig.link != address(0));
    }
}
