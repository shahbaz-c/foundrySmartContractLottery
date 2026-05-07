// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

/**
 * @author  0xGaladhrim
 * @title   A sample Raffle contract
 * @dev     Implements Chainlink VRFv2.5
 * @notice  This contract is for creating a sample raffle
 */
contract Raffle {
    uint256 private immutable ENTRANCE_FEE;

    constructor(uint256 entranceFee) {
        ENTRANCE_FEE = entranceFee;
    }

    function enterRaffle() public payable {}

    function pickWinner() public {}

    /* Getter Functions */

    function getEntranceFee() external view returns (uint256) {
        return ENTRANCE_FEE;
    }
}
