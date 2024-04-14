//SPDX-License-Identifier: MIT


pragma solidity 0.8.24;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {ERC404} from "./ERC404.sol";
import {ERC404UniswapV3Exempt} from "./ERC404UniswapV3Exempt.sol";
import {ERRORlib} from "errorLib.sol";
import {SafeTransferLib} from "https://github.com/Vectorized/solady/blob/main/src/utils/SafeTransferLib.sol";

/**
 * @title errortoken
 * @notice An ERC404 token
 * @author
 */
contract error is Ownable, ERC404, ERC404UniswapV3Exempt {
    // @dev The maximum total of ERC20 tokens that can exist.
    // @dev Each ERC721 is an underlying definition of 10 ** 18 ERC20 tokens.
    uint256 public constant MAX_TOTAL_SUPPLY = 404 * 10 ** 18;

    // @dev Once trading begins, trading cannot be stopped.
    bool public tradingStarted;

    address public constant MARKETING_WALLET = 0x53f793944634dAEC27b42d93993F61Ea254871e1;

    string public baseTokenURI;

    address public constant uniswapSwapRouter_ = 0x68b3465833fb72A70ecDF485E0e4C7bD8665Fc45;
    address public constant uniswapV3NonfungiblePositionManager_ = 0xC36442b4a4522E871399CD717aBDD847Ab11FE88;

    // CONSTRUCTOR
    constructor()
        ERC404("ERROR", "ERROR", 18)
        Ownable(msg.sender)
        ERC404UniswapV3Exempt(
            uniswapSwapRouter_,
            uniswapV3NonfungiblePositionManager_
        )
    {
        _setERC721TransferExempt(address(this), true);
        _setERC721TransferExempt(msg.sender, true);
        _setERC721TransferExempt(MARKETING_WALLET, true);

        _mintERC20(msg.sender, MAX_TOTAL_SUPPLY);
    }

    /**
     * @dev Modifier to check if trading is ready.
     * @param _from The address to transfer from.
     */
    modifier onlyTrading(address _from) {
        // @dev Check if trading has been enabled yet.
        if (tradingStarted == false) {
            // @dev Exempt mints as well as transfers from the owner.
            if (_from != address(0) && _from != owner()) {
                revert ERRORlib.TokenLoading();
            }
        }

        _;
    }

    function setTokenURI(string memory _tokenURI) external onlyOwner {
        baseTokenURI = _tokenURI;
    }

        function setBaseUri(string memory _tokenURI) external onlyOwner {
        baseTokenURI = _tokenURI;
    }


    /**
     * @notice Allow the owner to set the trading status
     */
    function EnableTrading() external onlyOwner {
        tradingStarted = true;
    }

    /**
     * @notice Allow the owner to withdraw the contract balance.
     */
    function withdraw() external onlyOwner {
        SafeTransferLib.safeTransferETH(owner(), address(this).balance);
    }

    /**
     * @dev Recovers a `tokenAmount` of the ERC20 `tokenAddress` locked into this contract
     * and sends them to the `tokenReceiver` address.
     *
     * @param tokenAddress The contract address of the token to recover.
     * @param tokenReceiver The address that will receive the recovered tokens.
     * @param tokenAmount Number of tokens to be recovered.
     */
    function recoverERC20(
        address tokenAddress,
        address tokenReceiver,
        uint256 tokenAmount
    ) external onlyOwner {
        IERC20(tokenAddress).transfer(tokenReceiver, tokenAmount);
    }

    /**
     * @dev Recovers the `tokenId` of the ERC721 `tokenAddress` locked into this contract
     * and sends it to the `tokenReceiver` address.
     *
     * @param tokenAddress The contract address of the token to recover.
     * @param tokenReceiver The address that will receive the recovered token.
     * @param tokenId The identifier for the NFT to be recovered.
     * @param data Additional data with no specified format.
     */
    function recoverERC721(
        address tokenAddress,
        address tokenReceiver,
        uint256 tokenId,
        bytes memory data
    ) external onlyOwner {
        IERC721(tokenAddress).safeTransferFrom(
            address(this),
            tokenReceiver,
            tokenId,
            data
        );
    }

    function tokenURI(uint256 _tokenId)
        public
        view
        override
        returns (string memory)
    {
        if (_getOwnerOf(_tokenId) == address(0)) {
            revert ERRORlib.TokenInvalid();
        }

        if (_tokenId > ID_ENCODING_PREFIX) {
            // if greater than the ID, get the unencoded ID
            _tokenId -= ID_ENCODING_PREFIX;
        }

        string memory currentId = Strings.toString(_tokenId);

        if (bytes(baseTokenURI).length > 0) {
            return string.concat(baseTokenURI, currentId);
        }

        return string.concat(
            "data:application/json;utf8,",
            '{"name": "ERROR #',
            currentId,
            '",',
            '"description": "Error: [noun] The occurrence of an incorrect result produced by a computer.|",',
            '"image": "https://www.error.computer/"}'
        );
    }

    /**
     * @notice ERC20 trading prevention until the time is ready.
     * @param _from The address to transfer from.
     * @param _to The address to transfer to.
     * @param _value The amount to transfer.
     */
    function _transferERC20(
        address _from,
        address _to,
        uint256 _value
    ) internal override onlyTrading(_from) {
        super._transferERC20(_from, _to, _value);
    }

    /**
     * @notice ERC721 trading prevention until the time is ready.
     * @dev Realistically this should never be hit, but it is here just
     *      to handle edge-cases where the ERC721 is being transferred
     *      before the ERC20 is ready to be traded.
     * @param _from The address to transfer from.
     * @param _to The address to transfer to.
     * @param _id The id to transfer.
     */
    function _transferERC721(
        address _from,
        address _to,
        uint256 _id
    ) internal override onlyTrading(_from) {
        super._transferERC721(_from, _to, _id);
    }

    function setERC721TransferExempt(address account_, bool value_)
        external
        onlyOwner
    {
        _setERC721TransferExempt(account_, value_);
    }
}