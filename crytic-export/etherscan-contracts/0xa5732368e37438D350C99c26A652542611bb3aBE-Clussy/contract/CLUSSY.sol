// SPDX-License-Identifier: MIT

pragma solidity 0.8.23;

/// @dev Core abstracts of Clussy.
import {ERC404} from "./404/ERC404.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

/// @dev Helper libraries to ensure seamless integration.
import {LibClussy} from "./libs/Clussy.lib.sol";
import {SafeTransferLib} from "./solady/SafeTransferLib.sol";
import {LibString} from "./solady/LibString.sol";

/**
 * @title Clussy: 🤡🤡🤡🤡🤡🤡
 * @notice An experimental ERC4🤡4 token with clussy.
 * @author art dev: 🤡
 * @author contract dev: 🤡
 */

contract Clussy is ERC404, Ownable {
    using LibString for uint256;

    /// @dev The URL or IPFS Link to the metadata for the tokenURI.
    string public baseTokenURI;

    /// @dev State var to effectively revoke access to transfer control.
    bool public trading;

    /// @dev State var to effectively revoke access to transfer control.
    bool public locked;

    /// @dev Control over minting status.
    bool private _mintSwitch;

    /// @dev Lock bool to prevent the createAllTokens function from being called twice, even if the logic checks should prevent that.
    bool private allTokensMinted;

    /// @dev Variable to hold the total desired erc20 supply entered during contract creation.
    uint256 private maxTotalSupply;

    /// @dev Variable to hold the mint price set during contract creation.
    uint256 private mintPrice;

    /// @dev Variable to hold the mint price set during contract creation.
    uint256 private walletLimit;

    /**
     * @dev Modifier to check if trading is ready.
     * @param $from The address to transfer from.
     */
    modifier onlyTrading(address $from) {
        /// @dev Exempt mints as well as transfers from the owner from
        ///      the trading status check.
        if (trading == false) {
            if ($from != address(0) && $from != owner()) {
                revert LibClussy.TokenLoading();
            }
        }

        _;
    }

    /// @dev Initialize the contract.
    constructor(address $owner, string memory $baseTokenURI, string memory $name, string memory $symbol, uint8 $decimals, uint256 $maxTotalSupplyERC721, uint256 $wholeTokensToOwner, uint256 $mintPriceinWEI, uint256 $mintWalletLimit) ERC404($name, $symbol, $decimals) Ownable($owner) {
        /// @dev Set the base token URI.
        baseTokenURI = $baseTokenURI;

        /// @dev Make owner erc721 Transfer Exempt at contract creation.
        _erc721TransferExempt[$owner] = true;

        /// @dev Transfer desired portion of whole tokens to wallet owner.
        balanceOf[$owner] = $wholeTokensToOwner * units;

        /// @dev Modifies total erc20 Supply to reflect the amount of whole tokens transferred to the owner wallet. Set as zero if no tokens are to be transferred to the owner.
        totalSupply = $wholeTokensToOwner * units;

        /// @dev Assigns the MAX total erc20 supply with the constructor inputs, totalERC721 supply * decimal units desired for fractionalization.
        maxTotalSupply = $maxTotalSupplyERC721 * units;
    
        /// @dev Sets mint price from amount provided in contract creation. Set as zero if not using mint function. 
        mintPrice = $mintPriceinWEI;

        /// @dev Sets Wallet limit for mint. If no limit, set to same number as maxTotalSupplyERC721. Must be a minimum of one whole token, or no one can mint. 
        walletLimit = $mintWalletLimit;
    }

    /**
     * @notice Mint function that allows a user to mint their individual tokens
     * recipient - The address that the tokens are to be sent to.
     * amount- The amount of erc721 tokens to send to that address
     **/
    function mint(uint256 amount) public payable {
        /// @dev Checks user balance of this contracts ERC20 token
        uint256 userBalance = this.erc20BalanceOf(msg.sender);

        /// @dev Sets variable to represent erc721 amounts.
        uint256 amountToken = amount * units;

        /// @dev Checks if the transaction is being sent with enough eth to match the mint price.
        if (msg.value < mintPrice * amount) revert LibClussy.PaymentInvalid();

        /// @dev Prevents public minting if toggle is true.
        if (_mintSwitch == false){
            revert LibClussy.TokenLoading();
        }

        /// @dev Prevent the max supply from being exceeded.
        if (maxTotalSupply < totalSupply + amountToken) {
            revert LibClussy.SupplyInsufficient();
        }

        /// @dev Checks user balance with total amount to be added to be sure that the user does not exceed the mint wallet limit.
        if (userBalance + amountToken > walletLimit * units) {
           revert LibClussy.MintMaximum();
        }

        /// @dev Make sure that minting status has not been locked.
        if(locked == true) revert LibClussy.TradingLocked();

        /// @dev Mint the tokens to the recipient.
        _mintERC20(msg.sender, amountToken);
    }

    /**
     * @notice Airdrop tokens to the users.
     * @param $recipients Array of recipients to airdrop to.
     * @param $amounts Array of amounts to airdrop to each recipient.
     */
    function ownerAirdrop(address[] calldata $recipients, uint256[] calldata $amounts) public onlyOwner {
        /// @dev Prevent array issues.
        if ($recipients.length != $amounts.length) {
            revert LibClussy.MintInvalid();
        }

        /// @dev Send the tokens to the recipients from the owner's wallet.
        for (uint256 i; i < $recipients.length; i++) {
            transfer($recipients[i], $amounts[i]);
        }
    }

    /// @dev set mint lock 
    function mintSwitch(bool value) public onlyOwner {
        _mintSwitch = value;
    }

    /**
     * @notice Allow the owner to set the ERC721 transfer exempt status.
     * @dev This function is only available to the owner and enables the ability
     *      to prevent NFT conversion for specific addresses.
     * @dev This is used for the liquidity pool as well as a few other instances.
     * @param $account The account to set the ERC721 transfer exempt status of.
     * @param $value The value to set the ERC721 transfer exempt status to.
     */
    function setERC721TransferExempt(address $account, bool $value) public onlyOwner {
        /// @dev Control the fractionalization allowances.
        _erc721TransferExempt[$account] = $value;
    }

        /// @dev allows Owner to set whitelist value for multiple accounts in one call.
    function setMultiERC721TransferExempt(address[] calldata $accounts, bool $value) public onlyOwner {
        for (uint256 i; i < $accounts.length; i++) {
            _erc721TransferExempt[$accounts[i]] = $value;
        }
    }

    /**
     * @notice Allow the owner to set the base token URI.
     * @dev This function is only available to the owner and enables the ability
     *      to set the base token URI for the tokenURI.
     * @param $uri The URI to set as the base token URI.
     */
    function setBaseTokenURI(string memory $uri) public onlyOwner {
        baseTokenURI = $uri;
    }

    /**
     * @notice Allow the owner to set the trading status.
     * @param $trading The status to set the trading status to.
     */
    function setTrading(bool $trading) public onlyOwner {
        /// @dev Make sure that trading status has not been locked.
        if(locked == true) revert LibClussy.TradingLocked();

        /// @dev Update the state of trading for a specific user.
        trading = $trading;
    }

    /**
     * @notice Revoke access to the transfer control.
     * @param $locked The status to set the locked status to.
     */
    function setLocked(bool $locked) public onlyOwner {
        /// @dev Make sure that trading status has not been locked.
        if(locked == true) revert LibClussy.TradingLocked();

        /// @dev Update the state of trading for all users.
        locked = $locked;
    }

    /// @dev function to cheaply produce the rest of the tokens in the case that all the tokens available for mint are not minted. Makes it easy to throw them in a LP after.
    function createAllTokens() public onlyOwner {
        if(allTokensMinted == true) revert LibClussy.MintMaximum();
        balanceOf[owner()] = maxTotalSupply - totalSupply + balanceOf[owner()];
        totalSupply = maxTotalSupply;
        allTokensMinted = true;
    }

    /// @dev emits on-chain event that prompts opensea to update metadata for all tokens.
    function updateMetadata() public onlyOwner {
        emit LibClussy.BatchMetadataUpdate(0, type(uint256).max);
    }

    /**
     * @notice Allow the owner to withdraw the contract balance.
     */
    function withdraw() public onlyOwner {
        SafeTransferLib.safeTransferETH(owner(), address(this).balance);
    }

    /**
     * @notice ERC721 metadata for tokenURI to return image.
     * @param $id The id of the token to return the image for.
     * @return $uri The URI of the token to return the image for.
     */
    function tokenURI(uint256 $id) public view override returns (string memory) {
        /// @dev Make sure the token has an owner (ie: it exists).
        if (_getOwnerOf($id) == address(0)) revert LibClussy.TokenInvalid();

        /// @dev The token ID without the encoding shift.
        uint256 tokenId = $id - (1 << 255);
        
        /// @dev Concat the URI string with the tokenId and add .json at the end
        return string.concat(baseTokenURI, tokenId.toString(), ".json");
    }

    /**
     * @notice ERC20 trading prevention until the time is ready.
     * @param $from The address to transfer from.
     * @param $to The address to transfer to.
     * @param $value The amount to transfer.
     */
    function _transferERC20(address $from, address $to, uint256 $value) internal override onlyTrading($from) {
        super._transferERC20($from, $to, $value);
    }

    /**
     * @notice ERC721 trading prevention until the time is ready.
     * @dev Realistically this should never be hit, but it is here just
     *      to handle edge-cases where the ERC721 is being transferred
     *      before the ERC20 is ready to be traded.
     * @param $from The address to transfer from.
     * @param $to The address to transfer to.
     * @param $id The id to transfer.
     */
    function _transferERC721(address $from, address $to, uint256 $id) internal override onlyTrading($from) {
        super._transferERC721($from, $to, $id);
    }
}