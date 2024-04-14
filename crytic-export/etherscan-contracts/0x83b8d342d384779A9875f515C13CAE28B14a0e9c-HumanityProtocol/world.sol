/*
 * Animoca Brands' vision through the Humanity Protocol is to extend digital property rights to gamers and Internet users worldwide,
 * paving the way for an open metaverse. 
 *
 * For more information or inquiries, contact us at: humans@cfh.xyz
 */
pragma solidity ^0.8.20;

import "@openzeppelin/contracts@5.0.2/token/ERC20/ERC20.sol";

contract HumanityProtocol is ERC20 {
    constructor() ERC20("Humanity Protocol", "HP") {
        _mint(msg.sender, 8000000000 * 10 ** decimals());
    }
}
