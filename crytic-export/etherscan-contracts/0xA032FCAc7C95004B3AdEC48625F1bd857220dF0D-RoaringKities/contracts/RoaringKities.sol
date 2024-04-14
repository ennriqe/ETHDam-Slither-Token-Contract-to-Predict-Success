// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20 <0.9.0;

import "@franknft.eth/erc721-f/contracts/token/ERC721/ERC721FCOMMON.sol";

/**
 * @title RoaringKities
 *
 * @dev RoaringKities implementation of [ERC721F]
 */
contract RoaringKities is ERC721FCOMMON {
    uint256 public constant MAX_TOKENS = 5555;
    uint256 public constant MAX_PURCHASE = 11; // one to big to save gas
    uint256 public tokenPrice = 0 ether;
    bool public preSaleIsActive;
    bool public saleIsActive;
    bool public freeMintActive;
    mapping(address => uint256) private mintAmount;
    address private constant FRANK = 0xF40Fd88ac59A206D009A07F8c09828a01e2ACC0d;

    modifier validMintRequest(uint256 numberOfTokens) {
        require(numberOfTokens > 0, "numberOfNfts cannot be 0");
        require(
            mintAmount[msg.sender] + numberOfTokens < MAX_PURCHASE,
            "Purchase would exceed max mint for walet"
        );
        _;
    }

    constructor() ERC721FCOMMON("Roaring Kitteh", "kitteh", msg.sender) {
        setBaseTokenURI(
            "ipfs://QmfRcQPgYDEAuAGbUs7CQxopDSKcvVcC41rAfrdvjJxJce/"
        );
        _mint(FRANK, 0);
    }

    /**
     * Mint Tokens to a wallet.
     */
    function airdrop(address to, uint256 numberOfTokens) public onlyOwner {
        uint256 supply = totalSupply();
        require(
            supply + numberOfTokens <= MAX_TOKENS,
            "Reserve would exceed max supply of Tokens"
        );
        unchecked {
            for (uint256 i = 0; i < numberOfTokens; ) {
                _safeMint(to, supply + i);
                i++;
            }
        }
    }

        /**
     * @dev airdrop a specific amount of tokens to a list of addresses
     */
    function airdrop(address[] calldata addresses, uint amt_each) external onlyOwner {
        uint length = addresses.length;
        uint256 supply = totalSupply();
        require(
            supply + amt_each*length <= MAX_TOKENS,
            "Reserve would exceed max supply of Tokens"
        );    
        unchecked {     
            for (uint i=0; i < length;) {
                for (uint256 x = 0; x < amt_each; ) {
                    _safeMint(addresses[i], supply + x);
                    x++;
                }
                supply += amt_each;
                i++;
            }
        }
    }


    /**
     * Changes the state of saleIsActive from true to false and false to true
     * @dev If saleIsActive becomes `true` sets preSaleIsActive to `false`
     */
    function flipSaleState() external onlyOwner {
        saleIsActive = !saleIsActive;
    }

    function canMint(address wallet) external view returns (uint256) {
        return (MAX_PURCHASE-1) - mintAmount[wallet];

    }

    /**
     * @notice Mints a certain number of tokens
     * @param numberOfTokens Total tokens to be minted, must be larger than 0 and at most 30
     */
    function mint(uint256 numberOfTokens)
        external
        payable
        validMintRequest(numberOfTokens)
    {
        require(msg.sender == tx.origin, "No Contracts allowed.");
        require(saleIsActive, "Sale NOT active yet");
        uint256 supply = _totalMinted();
        require(
            supply + numberOfTokens <= 5056,
            "Purchase would exceed max supply of Tokens"
        ); // reduced mint amount, max supply is to mint to the reserve

        unchecked {
            for (uint256 i; i < numberOfTokens; ) {
                _mint(msg.sender, supply + i); // no need to use safeMint as we don't allow contracts.
                i++;
            }
        }
        mintAmount[msg.sender] = mintAmount[msg.sender] + numberOfTokens;
    }


    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "Insufficient balance");
        _withdraw(owner(), balance);
    }

}
