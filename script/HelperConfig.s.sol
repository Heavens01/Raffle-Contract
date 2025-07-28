// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {Script} from "forge-std/Script.sol";
import {VRFCoordinatorV2_5Mock} from "@chainlink/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";
import {LinkToken} from "test/mocks/LinkToken.sol";

contract Constants {
    /* VRF Mock Values */
    uint96 public constant MOCK_BASE_FEE = 0.25 ether;
    uint96 public constant MOCK_GAS_PRICE = 1e9;
    int256 public constant MOCK_WEI_PER_UNIT_LINK = 4e15;

    uint256 public constant ETH_MAINNET_CHAIN_ID = 1;
    uint256 public constant SEPOLIA_CHAIN_ID = 11155111;
    uint256 public constant ANVIL_CHAIN_ID = 31337;
}

contract HelperConfig is Script, Constants {
    NetworkConfig public activeNetworkConfig; // public keyword automatically created a getter function

    struct NetworkConfig {
        uint256 raffleFee;
        uint256 interval;
        address vrfCoordinator;
        bytes32 keyHash;
        uint256 subscriptionId;
        uint32 callbackGasLimit;
        address link;
        address deployer;
    }

    constructor() {
        activeNetworkConfig = getNetworkConfigByChainId(block.chainid);
    }

    function getNetworkConfigByChainId(
        uint256 _chainId
    ) public returns (NetworkConfig memory) {
        if (_chainId == ETH_MAINNET_CHAIN_ID) {
            activeNetworkConfig = getEthMainnetConfig();
        } else if (_chainId == SEPOLIA_CHAIN_ID) {
            activeNetworkConfig = getSepoliaConfig();
        } else {
            activeNetworkConfig = getOrCreateAnvilConfig();
        }
        return activeNetworkConfig;
    }

    function getSepoliaConfig() public pure returns (NetworkConfig memory) {
        NetworkConfig memory sepoliaConfig = NetworkConfig({
            raffleFee: 0.01 ether,
            interval: 30,
            vrfCoordinator: 0x9DdfaCa8183c41ad55329BdeeD9F6A8d53168B1B,
            keyHash: 0x787d74caea10b2b357790d5b5247c2f63d1d91572a9846f780606e4d953677ae,
            subscriptionId: /*Create a subscription and put the ID here*/, // Go to chainlink vrf to create a subscription and add the raffle contract as consumer
            callbackGasLimit: 500000,
            link: 0x779877A7B0D9E8603169DdbD7836e478b4624789,
            deployer: /*Your wallet address here*/
        });
        return sepoliaConfig;
    }

    function getEthMainnetConfig() public pure returns (NetworkConfig memory) {
        NetworkConfig memory ethMainnetConfig = NetworkConfig({
            raffleFee: 0.01 ether,
            interval: 30,
            vrfCoordinator: 0xD7f86b4b8Cae7D942340FF628F82735b7a20893a,
            keyHash: 0x8077df514608a09f83e4e8d300645594e5d7234665448ba83f51a50f842bd3d9,
            subscriptionId: 0, // Not Set Due To Real MOney Needed
            callbackGasLimit: 500000,
            link: 0x514910771AF9Ca656af840dff83E8264EcF986CA,
            deployer: /*Your wallet address here*/
        });
        return ethMainnetConfig;
    }

    function getOrCreateAnvilConfig() public returns (NetworkConfig memory) {
        if (activeNetworkConfig.vrfCoordinator != address(0)) {
            return activeNetworkConfig;
        }
        vm.startBroadcast(); // Added no account inside the broadcast 'cause it's only related to the local network.
        VRFCoordinatorV2_5Mock vrfCoordinator = new VRFCoordinatorV2_5Mock(
            MOCK_BASE_FEE,
            MOCK_GAS_PRICE,
            MOCK_WEI_PER_UNIT_LINK
        );
        LinkToken linkToken = new LinkToken();
        vm.stopBroadcast();
        vm.startBroadcast(0x1804c8AB1F12E6bbf3894d4083f33e07309d1f38);
        // uint256 createdSubscriptionId = vrfCoordinator.createSubscription();
        vm.stopBroadcast();
        NetworkConfig memory anvilConfig = NetworkConfig({
            raffleFee: 0.01 ether,
            interval: 30,
            vrfCoordinator: address(vrfCoordinator),
            // GasLane/Keyhash value (Could be anything) doesn't mattter
            keyHash: 0x787d74caea10b2b357790d5b5247c2f63d1d91572a9846f780606e4d953677ae,
            subscriptionId: 0,
            callbackGasLimit: 500000,
            link: address(linkToken),
            deployer: 0x1804c8AB1F12E6bbf3894d4083f33e07309d1f38
        });
        vm.deal(anvilConfig.deployer, 100 ether);
        return anvilConfig;
    }

    function setSubscriptionId(uint256 _subscriptionId) public {
        require(_subscriptionId != 0, "Subscription ID cannot be zero");
        require(
            activeNetworkConfig.vrfCoordinator != address(0),
            "Network config not initialized"
        );

        activeNetworkConfig.subscriptionId = _subscriptionId;
    }
}
