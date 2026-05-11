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

    /* Errors */
    error Raffle__NotEnoughEthSent();

    uint16 private constant REQUEST_CONFIRMATIONS = 3;
    uint32 private constant NUM_WORDS = 1;
    uint256 private immutable ENTRANCE_FEE;
    uint256 private immutable INTERVAL; // @dev duration of the lottery in seconds
    bytes32 private immutable KEY_HASH;
    uint256 private immutable SUBSCRIPTION_ID;
    uint32 private immutable CALLBACK_GAS_LIMIT;
    address payable[] private s_players;
    uint256 private s_lastTimeStamp;

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
        s_lastTimeStamp = block.timestamp;
        KEY_HASH = gasLane;
        SUBSCRIPTION_ID = subscriptionId;
        CALLBACK_GAS_LIMIT = callbackGasLimit;
    }

    function enterRaffle() external payable {
        // validate to ensure user value is not less than required entrance fee
        if (msg.value < ENTRANCE_FEE) revert Raffle__NotEnoughEthSent();

        // add user address to s_players to track registration
        s_players.push(payable(msg.sender));

        // emit event
        emit EnteredRaffle(msg.sender);
    }

    function pickWinner() public {
        // check to see if enough times has passed
        if ((block.timestamp - s_lastTimeStamp) < INTERVAL) revert();

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

    /* Getter Functions */

    function getEntranceFee() external view returns (uint256) {
        return ENTRANCE_FEE;
    }
}
