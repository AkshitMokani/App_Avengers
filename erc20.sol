// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract TokenA is ERC20 
{
    constructor() ERC20("TokenA", "TA") 
    {
        _mint(msg.sender, 10000 * 10 ** decimals());
    }
}