// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {VRFConsumerBaseV2Plus} from "@chainlink/contracts/src/v0.8/vrf/dev/VRFConsumerBaseV2Plus.sol";
import {VRFV2PlusClient} from "@chainlink/contracts/src/v0.8/vrf/dev/libraries/VRFV2PlusClient.sol";

/**
 * @author  0xGaladhrim
 * @title   A sample Raffle contract
 * @dev     Implements Chainlink VRFv2.5
 * @notice  This contract is for creating a sample raffle
 */
contract Raffle is VRFConsumerBaseV2Plus {
    /* Events */
    event EnteredRaffle(address indexed player);
    event PickedWinner(address winner);

    /* Errors */
    error Raffle__NotEnoughEthSent();
    error Raffle__TransferFailed();
    error Raffle__RaffleNotOpen();
    error Raffle__UpkeepNotNeeded(uint256 balance, uint256 playersLength, uint256 raffleState);

    // Type declarations
    enum RaffleState {
        OPEN, // 0
        CALCULATING // 1
    }

    RaffleState private _raffleState;
    uint16 private constant REQUEST_CONFIRMATIONS = 3;
    uint32 private constant NUM_WORDS = 1;
    uint256 private immutable ENTRANCE_FEE;
    uint256 private immutable INTERVAL; // @dev duration of the lottery in seconds
    bytes32 private immutable KEY_HASH;
    uint256 private immutable SUBSCRIPTION_ID;
    uint32 private immutable CALLBACK_GAS_LIMIT;
    address payable[] private _players;
    uint256 private _lastTimeStamp;
    address private _recentWinner;

    constructor(
        uint256 entranceFee,
        uint256 interval,
        address vrfCoordinator,
        bytes32 gasLane,
        uint256 subscriptionId,
        uint32 callbackGasLimit
    ) VRFConsumerBaseV2Plus(vrfCoordinator) {
        ENTRANCE_FEE = entranceFee;
        INTERVAL = interval;
        _lastTimeStamp = block.timestamp;
        KEY_HASH = gasLane;
        SUBSCRIPTION_ID = subscriptionId;
        CALLBACK_GAS_LIMIT = callbackGasLimit;
        _raffleState = RaffleState.OPEN;
    }

    function enterRaffle() external payable {
        // validate to ensure user value is not less than required entrance fee
        if (msg.value < ENTRANCE_FEE) revert Raffle__NotEnoughEthSent();
        // validate to ensure raffle ticket cannot be bought when raffle state is calculating
        if (_raffleState != RaffleState.OPEN) revert Raffle__RaffleNotOpen();

        // add user address to s_players to track registration
        _players.push(payable(msg.sender));

        // emit event
        emit EnteredRaffle(msg.sender);
    }

    /**
     * @dev This is the function that the Chainlink Keeper nodes call
     * they look for `upkeepNeeded` to return True.
     * the following should be true for this to return true:
     * 1. The time interval has passed between raffle runs.
     * 2. The lottery is open.
     * 3. The contract has ETH.
     * 4. There are players registered.
     * 5. Implicitly, your subscription is funded with LINK.
     */
    function checkUpkeep(
        bytes memory /* checkData */
    )
        public
        view
        returns (
            bool upkeepNeeded,
            bytes memory /* performData */
        )
    {
        bool isOpen = RaffleState.OPEN == _raffleState;
        bool timePassed = ((block.timestamp - _lastTimeStamp) >= INTERVAL);
        bool hasPlayers = _players.length > 0;
        bool hasBalance = address(this).balance > 0;
        upkeepNeeded = (timePassed && isOpen && hasBalance && hasPlayers);
        return (upkeepNeeded, "");
    }

    // 1. Get a random number
    // 2. Use the random number to pick a player
    // 3. Automatically called
    function performUpkeep(
        bytes calldata /* performData */
    )
        external
    {
        // check to see if checkUpKeep returns true
        (bool upkeepNeeded,) = checkUpkeep("");
        if (!upkeepNeeded) {
            revert Raffle__UpkeepNotNeeded(address(this).balance, _players.length, uint256(_raffleState));
        }

        // change raffle state to calculating when picking winner
        _raffleState = RaffleState.CALCULATING;

        uint256 requestId = s_vrfCoordinator.requestRandomWords(
            VRFV2PlusClient.RandomWordsRequest({
                keyHash: KEY_HASH,
                subId: SUBSCRIPTION_ID,
                requestConfirmations: REQUEST_CONFIRMATIONS,
                callbackGasLimit: CALLBACK_GAS_LIMIT,
                numWords: NUM_WORDS,
                extraArgs: VRFV2PlusClient._argsToBytes(VRFV2PlusClient.ExtraArgsV1({nativePayment: false}))
            })
        );
    }

    function fulfillRandomWords(uint256 requestId, uint256[] calldata randomWords) internal override {
        uint256 indexOfWinner = randomWords[0] % _players.length;
        address payable recentWinner = _players[indexOfWinner];

        // store most recent winner in state
        _recentWinner = recentWinner;
        // reopen raffle after winner has been picked
        _raffleState = RaffleState.OPEN;

        // pay recent winner
        (bool success,) = recentWinner.call{value: address(this).balance}("");
        if (!success) revert Raffle__TransferFailed();

        // intialise new empty array over existing array
        _players = new address payable[](0);
        // update timestamp
        _lastTimeStamp = block.timestamp;

        // emit event
        emit PickedWinner(recentWinner);
    }

    /* Getter Functions */

    function getEntranceFee() external view returns (uint256) {
        return ENTRANCE_FEE;
    }
}
