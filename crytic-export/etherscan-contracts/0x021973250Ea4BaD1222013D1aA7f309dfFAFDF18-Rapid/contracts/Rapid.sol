pragma solidity ^0.8.23;

import "./UniswapTaxToken.sol";

contract Rapid is UniswapTaxToken {
    constructor(address uniswapAddress)
    UniswapTaxToken(uniswapAddress, 0, 888_000_000)
    ERC20("Rapid", "RAPID")
    {
    }
}
