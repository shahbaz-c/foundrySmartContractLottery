// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

/**
 * @author  0xGaladhrim
 * @title   A sample Raffle contract
 * @dev     Implements Chainlink VRFv2.5
 * @notice  This contract is for creating a sample raffle
 */
contract Raffle {
    /* Events */
    event EnteredRaffle(address indexed player);

    /* Errors */
    error Raffle__NotEnoughEthSent();

    uint256 private immutable ENTRANCE_FEE;
    uint256 private immutable INTERVAL; // @dev duration of the lottery in seconds
    address payable[] private s_players;
    uint256 private s_lastTimeStamp;

    constructor(uint256 entranceFee, uint256 interval) {
        ENTRANCE_FEE = entranceFee;
        INTERVAL = inteval;
        s_lastTimeStamp = block.timestamp;
    }

    function enterRaffle() external payable {
        // validate to ensure user value is not less than required entrance fee
        if (msg.value < i_entranceFee) revert Raffle__NotEnoughEthSent();

        // add user address to s_players to track registration
        s_players.push(payable(msg.sender));

        // emit event
        emit EnteredRaffle(msg.sender);
    }

    function pickWinner() public {
        // check to see if enough times has passed
        if ((block.timestamp - s_lastTimeStamp) < INTERVAL) revert();
    }

    /* Getter Functions */

    function getEntranceFee() external view returns (uint256) {
        return ENTRANCE_FEE;
    }
}
