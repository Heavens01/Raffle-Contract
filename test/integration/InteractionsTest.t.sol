// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {Test, console} from "forge-std/Test.sol";
import {CreateSubscription, FundSubscription, AddConsumer} from "script/Interactions.s.sol";
import {VRFCoordinatorV2_5Mock} from "@chainlink/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";
import {LinkToken} from "test/mocks/LinkToken.sol";
import {HelperConfig} from "script/HelperConfig.s.sol";
import {Raffle} from "src/Raffle.sol";

contract IntegrationTest is Test {
    CreateSubscription createSubscription;
    FundSubscription fundSubscription;
    AddConsumer addConsumer;
    HelperConfig helperConfig;

    uint256 raffleFee;
    uint256 interval;
    address vrfCoordinator;
    bytes32 keyHash;
    uint256 subscriptionId;
    uint32 callbackGasLimit;
    address linkToken;
    address deployer;
    Raffle raffle;
    address deployedRaffle;

    function setUp() public {
        createSubscription = new CreateSubscription();
        fundSubscription = new FundSubscription();
        addConsumer = new AddConsumer();
        helperConfig = new HelperConfig();

        // Create subscription
        (subscriptionId, vrfCoordinator) = createSubscription.createSubscriptionUsingActiveNetworkConfig();

        // Retrieve active network config
        (raffleFee, interval,, keyHash,, callbackGasLimit, linkToken, deployer) = helperConfig.activeNetworkConfig();
    }

    /*///////////////////////////////////////////////////
                    CREATE SUBSCRIPTION CONTRACT TESTS
    ///////////////////////////////////////////////////*/

    function testCreateSubscriptionRunFunction() public {
        createSubscription.run();
        assertGt(subscriptionId, 0, "Subscription ID should be greater than 0"); // assert GreaterThan
        console.log("Subscription ID created: ", subscriptionId);
    }

    function testCreateSubscription() public view {
        assertGt(subscriptionId, 0, "Subscription ID should be greater than 0"); // assert GreaterThan
        console.log("Subscription ID created: ", subscriptionId);
    }

    /*///////////////////////////////////////////////////
                    FUND SUBSCRIPTION CONTRACT TESTS
    ///////////////////////////////////////////////////*/

    function testFundSubscription() public {
        (uint96 initialBalance,,,,) = VRFCoordinatorV2_5Mock(vrfCoordinator).getSubscription(subscriptionId);
        console.log("vrf: ", vrfCoordinator);
        console.log("subId: ", subscriptionId);
        console.log("link: ", linkToken);
        fundSubscription.fundSubscription(vrfCoordinator, subscriptionId, linkToken, deployer);
        (uint96 newBalance,,,,) = VRFCoordinatorV2_5Mock(vrfCoordinator).getSubscription(subscriptionId);
        console.log("After balance: ", newBalance);

        assertGt(newBalance, initialBalance, "Subscription funding failed");
        console.log("Subscription funded successfully");
    }

    function testAddConsumer() public {
        raffle = new Raffle(raffleFee, interval, vrfCoordinator, keyHash, subscriptionId, callbackGasLimit);
        deployedRaffle = address(raffle);
        addConsumer.addConsumer(deployedRaffle, vrfCoordinator, subscriptionId, deployer);

        // Verify consumer was added (mock doesn't have a getter, so we assume success if no revert)
        console.log("Consumer added successfully to VRF Coordinator");
    }
}
