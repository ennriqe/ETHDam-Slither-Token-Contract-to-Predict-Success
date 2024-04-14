// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.22;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { IERC721 } from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import { OFT } from "@layerzerolabs/lz-evm-oapp-v2/contracts/oft/OFT.sol";

contract HarambeOFTFractionalizer is OFT {
    
    /// -----------------------------------
    /// -------- TOKEN INFORMATION --------
    /// -----------------------------------

    /// @notice the ERC721 token address of the vault's token
    address public tokenNFT;

    /// @notice the ERC721 token ID of the vault's token
    uint256 public id;

    /// @notice The number of tokens to be minted on contract creation
    uint256 public constant INITIAL_MINT = 1_000_000_000_000 ether;

    /// ------------------------
    /// -------- EVENTS --------
    /// ------------------------
    
    /// @notice An event emitted when someone redeems all tokens for the NFT
    event Redeem(address indexed redeemer);
    
    constructor(
        address _tokenNFT,
        uint256 _id,
        string memory _name,
        string memory _symbol,
        address _lzEndpoint,
        address _delegate
    ) OFT(_name, _symbol, _lzEndpoint, _delegate) Ownable(_delegate) {
        tokenNFT = _tokenNFT;
        id = _id;
        _mint(msg.sender, INITIAL_MINT);
    }

    /// @notice an external function to burn all ERC20 tokens to receive the ERC721 token
    function redeem() external {
        _burn(msg.sender, totalSupply());
        
        // transfer erc721 to redeemer
        IERC721(tokenNFT).transferFrom(address(this), msg.sender, id);

        emit Redeem(msg.sender);
    }
}
