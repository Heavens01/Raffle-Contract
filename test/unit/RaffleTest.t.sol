// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {Test, console} from "forge-std/Test.sol";
import {Raffle} from "src/Raffle.sol";
import {HelperConfig} from "script/HelperConfig.s.sol";
import {DeployRaffle} from "script/DeployRaffle.s.sol";
import {Vm} from "forge-std/Vm.sol";
import {VRFCoordinatorV2_5Mock} from "@chainlink/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";

contract RaffleTest is Test {
    Raffle public raffle;
    HelperConfig public helperConfig;

    uint256 raffleFee;
    uint256 interval;
    address vrfCoordinator;
    bytes32 keyHash;
    uint256 subscriptionId;
    uint32 callbackGasLimit;

    // Player  Initialization
    address public PLAYER = makeAddr("player");
    uint256 public constant PLAYER_STARTING_BALANCE = 10 ether;

    /* Events */
    event EnteredRaffle(address indexed participant);
    event LuckyWinner(address indexed winner);

    function setUp() external {
        DeployRaffle deployRaffle = new DeployRaffle();
        (raffle, helperConfig) = deployRaffle.deployContract();

        (raffleFee, interval, vrfCoordinator, keyHash, subscriptionId, callbackGasLimit,,) =
            helperConfig.activeNetworkConfig();

        vm.deal(PLAYER, PLAYER_STARTING_BALANCE);
    }

    modifier raffleEntered() {
        vm.prank(PLAYER);
        raffle.enterRaffle{value: raffleFee}();
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);
        _;
    }

    /*/////////////////////////////////////////////////////
                        ENTER RAFFLE TESTS
    /////////////////////////////////////////////////////*/

    function testRaffleStateInitializesInOpenState() public view {
        assert(raffle.getRaffleState() == Raffle.RaffleState.OPEN);
    }

    function testRaffleRevertsIfYouDontPayEnough() public {
        // Arrange
        vm.prank(PLAYER);
        // Act, Assert
        vm.expectRevert(Raffle.Raffle__NotEnoughEthSent.selector);
        raffle.enterRaffle();
    }

    function testRaffleRecordsPlayersWhenTheyEnter() public {
        // Arrange
        vm.prank(PLAYER);
        // Act
        raffle.enterRaffle{value: raffleFee}();
        // Assert
        assert(raffle.getRaffleParticipant(0) == PLAYER);
    }

    function testEnteringRaffleEmitsEvent() public {
        // Arrange
        vm.prank(PLAYER);
        // Act
        vm.expectEmit(true, false, false, false, address(raffle)); // Teling Foundry we are expecting an emit
        emit EnteredRaffle(PLAYER); // Telling foundry This is the kind of emit we are expecting
        // Assert
        raffle.enterRaffle{value: raffleFee}(); // Funding to emit from our contract which foundry crosschecks to be same with the above
    }

    function testDontEnterRaffleWhenRaffleStateIsCalculating() public {
        // Arrange
        vm.prank(PLAYER);
        raffle.enterRaffle{value: raffleFee}();
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);
        raffle.performUpkeep("");
        // Act, Assert
        vm.prank(PLAYER);
        vm.expectRevert(Raffle.Raffle__RaffleNotOpenYet.selector);
        raffle.enterRaffle{value: raffleFee}();
    }

    /*/////////////////////////////////////////////////////
                        CHECK UPKEEP TESTS
    /////////////////////////////////////////////////////*/

    function testCheckUpkeepReturnsFalseIfItHasNoBalance() public {
        // Arrange
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);
        // Act
        (bool upkeepNeeded,) = raffle.checkUpkeep("");
        // Assert
        assert(!upkeepNeeded); // Meaning it returns false for test to be successful
    }

    function testCheckUpkeepReturnsFalseIfRaffleIsNotOpen() public {
        // Arrange
        vm.prank(PLAYER);
        raffle.enterRaffle{value: raffleFee}();
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);
        raffle.performUpkeep("");
        // Act
        (bool upkeepNeeded,) = raffle.checkUpkeep("");
        // Assert
        assert(!upkeepNeeded); // Meaning it returns FALSE for test to be successful
    }

    function testCheckUpkeepReturnsFalseIfEnoughTimeHasNotPassed() public {
        // Arrange
        vm.prank(PLAYER);
        raffle.enterRaffle{value: raffleFee}();
        // Act
        (bool upkeepNeeded,) = raffle.checkUpkeep("");
        // Assert
        assert(!upkeepNeeded); // Meaning it returns FALSE for test to be successful
    }

    function testCheckUpkeepReturnsTrueWhenParametersAreGood() public {
        // Arrange
        vm.prank(PLAYER);
        raffle.enterRaffle{value: raffleFee}();
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);
        // Act
        (bool upkeepNeeded,) = raffle.checkUpkeep("");
        // Assert
        assert(upkeepNeeded); // Meaning it returns TRUE for test to be successful
    }

    /*/////////////////////////////////////////////////////
                        PERFORM UPKEEP TESTS
    /////////////////////////////////////////////////////*/

    function testPerformUpkeepCanOnlyRunIfCheckUpkeepIsTrue() public {
        // Arrange
        vm.prank(PLAYER);
        raffle.enterRaffle{value: raffleFee}();
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);
        // Act, Assert
        raffle.performUpkeep("");
    }

    function testPerformUpkeepRevertsIfCheckUpkeepIsFalse() public {
        // Arrange
        uint256 currentBal = 0;
        uint256 participants = 0;
        Raffle.RaffleState rState = raffle.getRaffleState();

        vm.prank(PLAYER);
        raffle.enterRaffle{value: raffleFee}();
        currentBal += raffleFee;
        participants = 1;
        // Act, Assert
        vm.expectRevert(
            abi.encodeWithSelector(Raffle.Raffle__UpkeepNotNeeded.selector, currentBal, participants, rState)
        );
        raffle.performUpkeep("");
    }

    function testPerformUpkeepUpdatesRaffleStateAndEmitsRequestId() public raffleEntered {
        // Act
        vm.recordLogs();
        raffle.performUpkeep("");
        Vm.Log[] memory entries = vm.getRecordedLogs();
        bytes32 requestId = entries[1].topics[1];
        // Assert
        assert(uint256(requestId) == 1);
        // Just asserting that the state changed for confirmation purposes
        assert(raffle.getRaffleState() == Raffle.RaffleState.CALCULATING);
        // assert(uint256(raffle.getRaffleState() == 1));
    }

    /*/////////////////////////////////////////////////////
                    FULFILL RANDOM WORDS TESTS
    /////////////////////////////////////////////////////*/

    function testFulfillRandomWordsCanOnlyBecalledAfterPerformUpkeep(uint256 randomRequestId) public raffleEntered {
        // Arrange, Act, Assert
        vm.expectRevert(VRFCoordinatorV2_5Mock.InvalidRequest.selector);
        /**
         * @dev we are using the mock to call the function which allows anybody to call this fullfillRandomWords
         * @dev And in this case, the test itself is the one calling the fullfilRandomWords function
         */
        VRFCoordinatorV2_5Mock(vrfCoordinator).fulfillRandomWords(randomRequestId, address(raffle));
    }

    function testFulfillRandomWordsPicksAWinnerResetsAndSendsMoney() public raffleEntered {
        // Arrange
        uint256 additionalEntrants = 3;
        uint256 startingIndex = 1;
        for (uint256 i = startingIndex; i <= additionalEntrants; i++) {
            address player = address(uint160(i));
            hoax(player, 1 ether);
            raffle.enterRaffle{value: raffleFee}();
        }
        uint256 startingTimeStamp = raffle.getLastTimeStamp();
        uint256 winnerBalance = address(uint160(1)).balance;
        // Act
        vm.recordLogs();
        raffle.performUpkeep("");
        Vm.Log[] memory entries = vm.getRecordedLogs();
        bytes32 requestId = entries[1].topics[1];
        VRFCoordinatorV2_5Mock(vrfCoordinator).fulfillRandomWords(uint256(requestId), address(raffle));
        // Assert
        address winner = raffle.getRecentWinner();
        // We knew the winner would be address(uint160(1))
        assert(winner == address(uint160(1)));
        assert(raffle.getRaffleParticipants().length == 0);
        assert(raffle.getRaffleState() == Raffle.RaffleState.OPEN);
        assert(raffle.getLastTimeStamp() > startingTimeStamp);
        // Asserting winner received prize
        uint256 prize = raffleFee * (additionalEntrants + 1);
        assert(winnerBalance + prize == address(uint160(1)).balance);
    }

    /*/////////////////////////////////////////////////////
                        RECEIVE FUNCTION TESTS
    /////////////////////////////////////////////////////*/

    function testReceiveFunctionWorks() public {
        // Arrange
        vm.prank(PLAYER);
        // Act
        (bool success,) = address(raffle).call{value: raffleFee}("");
        // Assert
        assert(success);
        assert(raffle.getRaffleParticipant(0) == PLAYER);
    }

    /*/////////////////////////////////////////////////////
                        FALLBACK FUNCTION TESTS
    /////////////////////////////////////////////////////*/

    function testFallbackFunctionWorks() public {
        // Arrange
        vm.prank(PLAYER);
        // Act
        (bool success,) = address(raffle).call{value: raffleFee}("0x1234"); // Added some msg.data: "0x1234" to trigger fallback function
        // Assert
        assert(success);
        assert(raffle.getRaffleParticipant(0) == PLAYER);
    }

    /*/////////////////////////////////////////////////////
            EXTRA CURRICULAR TEST TO UP TEST COVERAGE
    /////////////////////////////////////////////////////*/

    // The only getter that has not been used in the above tests
    function testRaffleFeeGetterFunction() public view {
        // Arrange
        uint256 returnedRaffleFee = 0.01 ether;
        // Act, Assert
        assert(raffle.getRaffleFee() == returnedRaffleFee);
    }
}
