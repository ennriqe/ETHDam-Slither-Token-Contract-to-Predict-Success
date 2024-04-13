// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "erc721a/contracts/ERC721A.sol";

contract TOMMY is ERC721A, Ownable {
    // Using Strings for string;
    using Strings for uint256;

    // Using SafeERC20 for IERC20;
    using SafeERC20 for IERC20;

    // USDT Interface
    IERC20 private USDTToken;

    // NFT Mint Price
    uint256 public PRICE = 0.01 ether;

    // NFT Mint Price with USDT ($300)
    uint256 public PRICE_USDT = 300 * 10 ** 18;

    // NFT Total Supply
    uint256 public constant MAX_SUPPLY = 512;

    // Owner User List
    mapping(address => uint256) public _owners;

    // NFT Token URI
    mapping(uint256 => string) private _tokenURIs;
    // =============================================================
    //                          CONSTRUCTOR

    /**
     * @dev Initialize Variables
     * @param name          NFT Token Name
     * @param symbol        NFT Token Symbol
     * @param initialOwner  Smart Contract Owner Wallet Address
     * @param usdtToken     USDT Token Addresss
     */
    constructor(
        string memory name,
        string memory symbol,
        address initialOwner,
        address usdtToken
    ) ERC721A(name, symbol) Ownable(initialOwner) {
        USDTToken = IERC20(usdtToken);
    }

    // =============================================================

    // =============================================================
    //                          Internal Method   

    /**
     * @dev Start NFT Token ID
     */
    function _startTokenId() internal view override returns (uint256) {
        return 1;
    }

    // =============================================================
    //                          Payable Methods

    /**
     * @dev Mint NFT Token
     * @param _recipient     Address want to mint
     * @param _tokenURI      NFT TokenURI want to mint
     */

    function mint(
        address _recipient,
        string memory _tokenURI
    ) external payable {
        require(totalSupply() + 1 <= MAX_SUPPLY, "exceed max supply of tokens");
        require(msg.value >= PRICE, "insufficient ether value");

        _owners[_recipient] += 1;
        _tokenURIs[totalSupply() + 1] = _tokenURI;
        _safeMint(_recipient, 1);
    }

    /**
     * @dev Mint NFT Token with USDT
     * @param _recipient     Address want to mint
     * @param _tokenURI      NFT TokenURI want to mint
     */

    function mintUSDT(address _recipient, string memory _tokenURI) external {
        require(totalSupply() + 1 <= MAX_SUPPLY, "exceed max supply of tokens");
        require(
            USDTToken.transferFrom(msg.sender, address(this), PRICE_USDT),
            "USDT transfer failed"
        );

        _owners[_recipient] += 1;
        _tokenURIs[totalSupply() + 1] = _tokenURI;
        _safeMint(_recipient, 1);
    }

    // =============================================================

    // =============================================================
    //                          View Methods

    /**
     * @dev Get NFT Metadata with TokenID
     * @param tokenID NFT Token ID
     * @return metadata NFT Token Metadata
     */

    function tokenURI(
        uint256 tokenID
    ) public view override returns (string memory) {
        require(_exists(tokenID), "Token does not exist");

        return _tokenURIs[tokenID];
    }

    // =============================================================

    // =============================================================
    //                          OWNER Methods

    /**
     * @dev Set Price for NFT Minting
     */

    function changePrice(
        uint256 _price,
        uint256 _price_usdt
    ) external onlyOwner {
        PRICE = _price;
        PRICE_USDT = _price_usdt;
    }

    /**
     * @dev Withdraw the Money
     */

    function withdraw() external onlyOwner {
        address _owner = owner();

        // Withdraw USDT tokens
        uint256 usdtBalance = USDTToken.balanceOf(address(this));
        USDTToken.transfer(_owner, usdtBalance);

        uint256 ethbalance = address(this).balance;
        payable(_owner).transfer(ethbalance);
    }

    // =============================================================
}
