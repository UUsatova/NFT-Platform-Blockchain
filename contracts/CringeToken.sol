// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/**
 * @title custom token for MLMsystem
 * @author UUsatova
 */
contract CringeToken is ERC20 {
    /**
     * @dev sets initial supply of tokens
     * @param initialSupply  - ammount initial supply of tokens
     */
    constructor(uint256 initialSupply) ERC20("Cringe", "CT") {
        _mint(msg.sender, initialSupply);
    }
}
