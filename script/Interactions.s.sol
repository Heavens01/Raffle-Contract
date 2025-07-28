// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import {Script, console} from "forge-std/Script.sol";
import {HelperConfig, Constants} from "./HelperConfig.s.sol";
import {VRFCoordinatorV2_5Mock} from "@chainlink/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";
import {LinkToken} from "test/mocks/LinkToken.sol";
import {Raffle} from "src/Raffle.sol";
import {DevOpsTools} from "lib/foundry-devops/src/DevOpsTools.sol";

contract CreateSubscription is Script {
    function run() public {
        createSubscriptionUsingActiveNetworkConfig();
    }

    function createSubscriptionUsingActiveNetworkConfig() public returns (uint256, address) {
        HelperConfig helperConfig = new HelperConfig();
        (,, address vrfCoordinator,,,,, address deployer) = helperConfig.activeNetworkConfig();
        (uint256 subId,) = createSubscription(vrfCoordinator, deployer);
        return (subId, vrfCoordinator);
    }

    function createSubscription(address _vrfCoordinator, address _deployer) public returns (uint256, address) {
        console.log("Creating subscription on chain Id: ", block.chainid);
        vm.startBroadcast(_deployer);
        uint256 subId = VRFCoordinatorV2_5Mock(_vrfCoordinator).createSubscription();
        vm.stopBroadcast();
        console.log("Your subscription Id: ", subId);
        console.log("Please update your subscription Id in your HelperConfig.s.sol");
        return (subId, _vrfCoordinator);
    }
}

contract FundSubscription is Script, Constants {
    uint256 public constant FUND_AMOUNT = 3 ether; // Same as 300 LINK cause it runs in 18 decimal places too.

    function run() public {
        fundSubscriptionUsingActiveNetworkConfig();
    }

    function fundSubscriptionUsingActiveNetworkConfig() public {
        HelperConfig helperConfig = new HelperConfig();
        (,, address vrfCoordinator,, uint256 subscriptionId,, address linkToken, address deployer) =
            helperConfig.activeNetworkConfig();
        fundSubscription(vrfCoordinator, subscriptionId, linkToken, deployer);
    }

    function fundSubscription(address _vrfCoordinator, uint256 _subscriptionId, address _linkToken, address _deployer)
        public
    {
        console.log("Funding subscription: ", _subscriptionId);
        console.log("Using vrfCoordinator: ", _vrfCoordinator);
        console.log("On chainId: ", block.chainid);

        if (block.chainid == ANVIL_CHAIN_ID) {
            vm.startBroadcast(_deployer);
            VRFCoordinatorV2_5Mock(_vrfCoordinator).fundSubscription(_subscriptionId, FUND_AMOUNT * 100);
            vm.stopBroadcast();
        } else {
            // If it is an online chain like sepolia or mainnet, etc
            vm.startBroadcast(_deployer);
            LinkToken(_linkToken).transferAndCall(_vrfCoordinator, FUND_AMOUNT, abi.encode(_subscriptionId));
            vm.stopBroadcast();
        }
    }
}

contract AddConsumer is Script {
    function run() public {
        address mostRecentlyDeployed = DevOpsTools.get_most_recent_deployment("Raffle", block.chainid);
        addConsumerUsingConfig(mostRecentlyDeployed);
    }

    function addConsumerUsingConfig(address _mostRecentlyDeployedContract) public {
        HelperConfig helperConfig = new HelperConfig();
        (,, address vrfCoordinator,, uint256 subId,,, address deployer) = helperConfig.activeNetworkConfig();
        addConsumer(_mostRecentlyDeployedContract, vrfCoordinator, subId, deployer);
    }

    function addConsumer(address _contractToAddToVrf, address _vrfCoordinator, uint256 _subId, address _deployer)
        public
    {
        console.log("Adding consumer contract: ", _contractToAddToVrf);
        console.log("To VRFCoordinator: ", _vrfCoordinator);
        console.log("On ChainId: ", block.chainid);
        vm.startBroadcast(_deployer);
        VRFCoordinatorV2_5Mock(_vrfCoordinator).addConsumer(_subId, _contractToAddToVrf);
        vm.stopBroadcast();
    }
}
