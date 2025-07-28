// Layout of Contract:
// version
// imports
// errors
// interfaces, libraries, contracts
// Type declarations
// State variables
// Events
// Modifiers
// Functions

// Layout of Functions:
// constructor
// receive function (if exists)
// fallback function (if exists)
// external
// public
// internal
// private
// view & pure functions

// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import {VRFConsumerBaseV2Plus} from "@chainlink/contracts/src/v0.8/vrf/dev/VRFConsumerBaseV2Plus.sol";
import {VRFV2PlusClient} from "@chainlink/contracts/src/v0.8/vrf/dev/libraries/VRFV2PlusClient.sol";

/**
 * @title Raffle Contract
 * @author Heavens01
 * @notice This is a simple raffle contract
 * @dev This contract uses the Chainlink VRF version 2 to generate random numbers
 */
contract Raffle is VRFConsumerBaseV2Plus {
    /* Errors */
    error Raffle__NotEnoughEthSent();
    error Raffle__RaffleEndTimeNotReached();
    error Raffle__FailedToSendFundsToWinner();
    error Raffle__RaffleNotOpenYet();
    error Raffle__UpkeepNotNeeded(uint256 balance, uint256 participants, RaffleState raffleState);

    /* Type Declarations */
    enum RaffleState {
        OPEN,
        CALCULATING
    }

    /* State Variables */
    /* Request Random Number related variables */
    uint16 private constant REQUEST_CONFIRMATIONS = 3;
    uint32 private constant NUM_WORDS = 1;

    bytes32 private immutable i_gasLane;
    uint256 private immutable i_subscriptionId;
    uint32 private immutable i_callbackGasLimit;

    /* Raffle related variables */
    //@dev duration of each lottery/raffle in seconds
    uint256 private immutable i_interval;
    uint256 private immutable i_raffleFee;

    address payable[] private s_raffleParticipants;

    // Last time the raffle winner was picked
    uint256 private s_lastTimeStamp;
    address payable private s_recentWinner;
    RaffleState private s_raffleState;

    /* Events */
    event EnteredRaffle(address indexed participant);
    event LuckyWinner(address indexed winner);
    event RequestedRandomnessId(uint256 indexed requestId);

    /* Constructor */
    constructor(
        uint256 _raffleFee,
        uint256 _interval,
        address _vrfCoordinator,
        bytes32 _keyHash,
        uint256 _subscriptionId,
        uint32 _callbackGasLimit
    ) VRFConsumerBaseV2Plus(_vrfCoordinator) {
        i_raffleFee = _raffleFee;
        i_interval = _interval;
        s_lastTimeStamp = block.timestamp;
        i_gasLane = _keyHash;
        i_subscriptionId = _subscriptionId;
        i_callbackGasLimit = _callbackGasLimit;
        s_raffleState = RaffleState.OPEN;
    }

    /* Receive function */
    receive() external payable {
        enterRaffle();
    }

    /* Fallback function */
    fallback() external payable {
        enterRaffle();
    }

    function enterRaffle() public payable {
        if (msg.value < i_raffleFee) {
            revert Raffle__NotEnoughEthSent();
        }
        if (s_raffleState != RaffleState.OPEN) {
            revert Raffle__RaffleNotOpenYet();
        }
        s_raffleParticipants.push(payable(msg.sender));
        emit EnteredRaffle(msg.sender);
    }

    /**
     *
     * @dev - This function is used to check if the upkeep is needed and is called by chainlink automation nodes
     * @dev - These are the condition to checked for it to return true:
     * 1. The time interval has passed between raffle runs.
     * 2. The lottery is open.
     * 3. The contract has ETH.
     * 4. There are players registered.
     * 5. Implicitly, your subscription is funded with LINK.
     * @param - ignored
     * @return upkeepNeeded - returns true when the stated conditions are met/true which is a condition
     * checked so that performUpkeep function would be called.
     * @return - ignored
     */
    function checkUpkeep(bytes memory /* checkData */ )
        public
        view
        returns (bool upkeepNeeded, bytes memory /* performData */ )
    {
        bool isOpen = s_raffleState == RaffleState.OPEN;
        bool timeHasPassed = ((block.timestamp - s_lastTimeStamp) >= i_interval);
        bool hasParticipants = s_raffleParticipants.length > 0;
        bool hasBalance = address(this).balance > 0;
        upkeepNeeded = isOpen && timeHasPassed && hasParticipants && hasBalance;
        return (upkeepNeeded, "");
    }

    /**
     *
     * @dev - This function is used to perform the upkeep and is called by chainlink automation nodes.
     * @dev - This function picks the winner of the raffle
     * @param - ignored
     */
    // CEI: checks, effects, interactions
    function performUpkeep(bytes calldata /* performData */ ) external {
        (bool upKeepNeeded,) = checkUpkeep("");
        if (!upKeepNeeded) {
            revert Raffle__UpkeepNotNeeded({
                balance: address(this).balance,
                participants: s_raffleParticipants.length,
                raffleState: s_raffleState
            });
        }
        s_raffleState = RaffleState.CALCULATING;

        VRFV2PlusClient.RandomWordsRequest memory request = VRFV2PlusClient.RandomWordsRequest({
            keyHash: i_gasLane,
            subId: i_subscriptionId,
            requestConfirmations: REQUEST_CONFIRMATIONS,
            callbackGasLimit: i_callbackGasLimit,
            numWords: NUM_WORDS,
            extraArgs: VRFV2PlusClient._argsToBytes(VRFV2PlusClient.ExtraArgsV1({nativePayment: false}))
        });
        uint256 requestId = s_vrfCoordinator.requestRandomWords(request);
        emit RequestedRandomnessId(requestId);
    }

    function fulfillRandomWords(
        uint256,
        /* requestId */
        uint256[] calldata randomWords
    ) internal override {
        uint256 winnerIndex = randomWords[0] % s_raffleParticipants.length;
        address payable winner = s_raffleParticipants[winnerIndex];
        s_recentWinner = winner;
        // Reset the raffle
        s_raffleParticipants = new address payable[](0);
        s_lastTimeStamp = block.timestamp;
        s_raffleState = RaffleState.OPEN;
        // Emit winner
        emit LuckyWinner(winner);
        // Send the funds to the winner
        (bool callSuccess,) = winner.call{value: address(this).balance}("");
        if (!callSuccess) {
            revert Raffle__FailedToSendFundsToWinner();
        }
    }

    /* Getters Functions */
    function getRaffleFee() external view returns (uint256) {
        return i_raffleFee;
    }

    function getRaffleParticipant(uint256 _indexOfPlayer) external view returns (address payable) {
        return s_raffleParticipants[_indexOfPlayer];
    }

    function getRaffleParticipants() external view returns (address payable[] memory) {
        return s_raffleParticipants;
    }

    function getRaffleState() external view returns (RaffleState) {
        return s_raffleState;
    }

    function getRecentWinner() external view returns (address payable) {
        return s_recentWinner;
    }

    function getLastTimeStamp() external view returns (uint256) {
        return s_lastTimeStamp;
    }
}
