//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";

abstract contract Ownable {
    event OwnershipTransferred(address indexed user, address indexed newOwner);

    error Unauthorized();
    error InvalidOwner();

    address public owner;

    modifier onlyOwner() virtual {
        if (msg.sender != owner) revert Unauthorized();

        _;
    }

    constructor(address _owner) {
        if (_owner == address(0)) revert InvalidOwner();

        owner = _owner;

        emit OwnershipTransferred(address(0), _owner);
    }

    function transferOwnership(address _owner) public virtual onlyOwner {
        if (_owner == address(0)) revert InvalidOwner();

        owner = _owner;

        emit OwnershipTransferred(msg.sender, _owner);
    }

    function revokeOwnership() public virtual onlyOwner {
        owner = address(0);

        emit OwnershipTransferred(msg.sender, address(0));
    }
}

abstract contract ERC721Receiver {
    function onERC721Received(address, address, uint256, bytes calldata) external virtual returns (bytes4) {
        return ERC721Receiver.onERC721Received.selector;
    }
}

/// @notice ERC7616
///         A gas-efficient, mixed ERC20 / ERC721 implementation
///         with native liquidity and fractionalization. You can
///         get the value token while holding on to the skin NFT
///
///
/// @dev    In order to support full functionality of ERC20 and ERC721
///         supply assumptions are made that slightly constraint usage.
///         Ensure decimals are sufficiently large (standard 18 recommended)
///         as ids are effectively encoded in the lowest range of amounts.
///
abstract contract ERC7616V2Upgradeable is Initializable, ContextUpgradeable, OwnableUpgradeable {
    // ERC20 Events
    event ERC20Transfer(address indexed from, address indexed to, uint256 amount);
    event Approval(address indexed owner, address indexed spender, uint256 amount);
    // ERC721 Events
    event Transfer(address indexed from, address indexed to, uint256 indexed id);
    event ERC721Approval(address indexed owner, address indexed spender, uint256 indexed id);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    // Errors
    error NotFound();
    error AlreadyExists();
    error InvalidRecipient();
    error InvalidSender();
    error UnsafeRecipient();
    error NoEnoughNFT();
    error AlreadySplitted();
    error AlreadyMerged();
    error InvalidTokenId();
    error ERC20InsufficientAllowance(address spender, uint256 allowance, uint256 needed);
    error ExceedMaxNftSupply();
    error Unauthorized();

    // Metadata
    /// @dev Token name
    string public name;

    /// @dev Token symbol
    string public symbol;

    /// @dev Decimals for fractional representation
    uint8 public decimals;

    /// @dev Total supply in fractionalized representation
    uint256 public totalSupply;

    /// @dev Total supply of NFTs
    uint256 public nftTotalSupply;

    /// @dev Current mint counter, monotonically increasing to ensure accurate ownership
    uint256 public minted;

    /// @dev Current mint counter, monotonically increasing to ensure accurate ownership
    uint256 public unit;

    // Mappings
    /// @dev Balance of user in fractional representation
    mapping(address => uint256) public balanceOf;
    mapping(address => uint256) public erc721BalanceOf;

    /// @dev Allowance of user in fractional representation
    mapping(address => mapping(address => uint256)) public allowance;

    /// @dev Approval in native representaion
    mapping(uint256 => address) public getApproved;

    /// @dev Approval for all in native representation
    mapping(address => mapping(address => bool)) public isApprovedForAll;

    /// @dev Owner of id in native representation
    mapping(uint256 => address) internal _ownerOf;

    /// @dev Default split state for new NFTs.
    bool private defaultSplitState;

    /// @dev Tracks whether the split state of an NFT is explicitly opposite to the default.
    mapping(uint256 => bool) private isSplitStateOpposite;

    function initialize(
        string memory _name,
        string memory _symbol,
        uint8 decimals_,
        uint256 _nftTotalSupply,
        address _owner,
        uint256 _unit,
        bool _defaultSplitState
    )
        public
        initializer
    {
        __Context_init_unchained();
        __Ownable_init_unchained();
        __ERC404_init_unchained(_name, _symbol, decimals_, _nftTotalSupply, _owner, _unit, _defaultSplitState);
    }

    function __ERC404_init_unchained(
        string memory _name,
        string memory _symbol,
        uint8 _decimals,
        uint256 _nftTotalSupply,
        address _owner,
        uint256 _unit,
        bool _defaultSplitState
    )
        internal
        initializer
    {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
        nftTotalSupply = _nftTotalSupply;
        unit = _unit;
        defaultSplitState = _defaultSplitState;
        _transferOwnership(_owner);
    }

    /**
     * @notice Determines the current split state of an NFT.
     * @param tokenId The ID of the NFT to check.
     * @return bool The current split state of the NFT, taking into account any explicit overrides.
     */
    function isSplit(uint256 tokenId) public view returns (bool) {
        // If the split state for this NFT is marked as opposite, return the opposite of the default.
        // Otherwise, return the default split state.
        return isSplitStateOpposite[tokenId] ? !defaultSplitState : defaultSplitState;
    }

    /**
     * @dev Sets the split state of an NFT to the specified value.
     * This function adjusts the isSplitStateOpposite mapping to ensure
     * the isSplit function returns the desired state.
     * @param id The ID of the NFT whose split state is being set.
     * @param state The desired split state for the NFT.
     */
    function setIsSplit(uint256 id, bool state) internal virtual {
        // Determine if the desired state differs from the default state.
        // If it does, isSplitStateOpposite should be true to indicate that
        // the actual state is opposite to the default, ensuring isSplit returns the correct value.
        // If the desired state is the same as the default, isSplitStateOpposite should be false.
        isSplitStateOpposite[id] = (state != defaultSplitState);
    }

    function erc20TotalSupply() public view virtual returns (uint256) {
        return totalSupply;
    }

    function erc721TotalSupply() public view virtual returns (uint256) {
        return nftTotalSupply;
    }

    /// @notice Function to find owner of a given native token
    function ownerOf(uint256 id) public view virtual returns (address owner) {
        owner = _ownerOf[id];
    }

    /// @notice tokenURI must be implemented by child contract
    function tokenURI(uint256 id) public view virtual returns (string memory);

    /// @notice For a token token id to be considered valid, it just needs
    ///         to fall within the range of possible token ids, it does not
    ///         necessarily have to be minted yet.
    function _isValidTokenId(uint256 id_) internal view returns (bool) {
        return id_ < nftTotalSupply;
    }

    /// @notice Function for mixed token approvals
    /// @dev This function assumes id / native if amount less than or equal to current max id
    function approve(address spender, uint256 amountOrId) public virtual returns (bool) {
        if (_isValidTokenId(amountOrId)) {
            return erc721Approve(spender, amountOrId);
        } else {
            return erc20Approve(spender, amountOrId);
        }
    }

    /// @notice Function for erc20 token approvals
    function erc20Approve(address spender, uint256 amount) public virtual returns (bool) {
        allowance[msg.sender][spender] = amount;

        emit Approval(msg.sender, spender, amount);

        return true;
    }

    /// @notice Function for erc20 token approvals
    function erc721Approve(address spender, uint256 tokenId) public virtual returns (bool) {
        address owner = _ownerOf[tokenId];

        if (msg.sender != owner && !isApprovedForAll[owner][msg.sender]) {
            revert Unauthorized();
        }

        getApproved[tokenId] = spender;

        emit Approval(owner, spender, tokenId);

        return true;
    }

    /// @notice Function native approvals
    function setApprovalForAll(address operator, bool approved) public virtual {
        isApprovedForAll[msg.sender][operator] = approved;
        allowance[msg.sender][operator] = type(uint256).max;

        emit ApprovalForAll(msg.sender, operator, approved);
    }

    /// @notice Function for splitting nft to skin NFT and value token
    function split(uint256 id) public virtual {
        if (isSplit(id) == true) {
            revert AlreadySplitted();
        }

        if (msg.sender != _ownerOf[id]) {
            revert InvalidSender();
        }

        setIsSplit(id, true);
        _transfer(address(0), msg.sender, _getUnit());
    }

    // Batch split function
    function splitBatch(uint256[] memory ids) public {
        for (uint256 i = 0; i < ids.length; ++i) {
            split(ids[i]); // Call the existing split function for each ID
        }
    }

    /// @notice Function for merging value token to skin NFT token make an original nft
    function merge(uint256 id) public virtual {
        if (isSplit(id) == false) {
            revert AlreadyMerged();
        }

        if (msg.sender != _ownerOf[id]) {
            revert InvalidSender();
        }

        setIsSplit(id, false);
        _transfer(msg.sender, address(0), _getUnit());
    }

    /// @notice Batch merge function
    function mergeBatch(uint256[] memory ids) public {
        for (uint256 i = 0; i < ids.length; ++i) {
            merge(ids[i]); // Call the existing merge function for each ID
        }
    }

    function _spendAllowance(address owner, address spender, uint256 value) internal virtual {
        uint256 allowed = allowance[owner][spender];

        if (allowed != type(uint256).max) {
            if (allowed < value) {
                revert ERC20InsufficientAllowance(spender, allowed, value);
            }
            unchecked {
                allowance[owner][spender] = allowed - value;
            }
        }
    }

    /// @notice Function for mixed transfers
    /// @dev This function assumes id / native if amount less than or equal to current max id
    function transferFrom(address from, address to, uint256 amountOrId) public virtual {
        if (to == address(0)) {
            revert InvalidRecipient();
        }

        if (_isValidTokenId(amountOrId)) {
            _nftTransfer(from, to, amountOrId);
        } else {
            _spendAllowance(from, msg.sender, amountOrId);
            _transfer(from, to, amountOrId);
        }
    }

    /// @notice Function for erc721 transfers
    function erc721TransferFrom(address from, address to, uint256 tokenId) public virtual {
        if (from == address(0)) {
            revert InvalidSender();
        }

        if (to == address(0)) {
            revert InvalidRecipient();
        }

        _nftTransfer(from, to, tokenId);
    }

    /// @notice Function for erc721 transfers
    function erc20TransferFrom(address from, address to, uint256 value) public virtual {
        if (from == address(0)) {
            revert InvalidSender();
        }

        if (to == address(0)) {
            revert InvalidRecipient();
        }

        _spendAllowance(from, msg.sender, value);
        _transfer(from, to, value);
    }

    /// @notice Function for fractional transfers
    function transfer(address to, uint256 amount) public virtual returns (bool) {
        return _transfer(msg.sender, to, amount);
    }

    /// @notice Internal function to handle the logic of transferring tokens
    function _safeTransfer(address from, address to, uint256 id, bytes memory data) internal {
        transferFrom(from, to, id);

        if (
            to.code.length != 0
                && ERC721Receiver(to).onERC721Received(msg.sender, from, id, data)
                    != ERC721Receiver.onERC721Received.selector
        ) {
            revert UnsafeRecipient();
        }
    }

    /// @notice Function for native transfers with contract support
    function safeTransferFrom(address from, address to, uint256 id) public virtual {
        _safeTransfer(from, to, id, "");
    }

    /// @notice Function for native transfers with contract support and callback data
    function safeTransferFrom(address from, address to, uint256 id, bytes calldata data) public virtual {
        _safeTransfer(from, to, id, data);
    }

    /// @notice Internal function for fractional transfers
    function _transfer(address from, address to, uint256 amount) internal returns (bool) {
        if (from == address(0)) {
            // Overflow check required: The rest of the code assumes that totalSupply never overflows
            totalSupply += amount;
        } else {
            balanceOf[from] -= amount;
        }

        if (to == address(0)) {
            unchecked {
                // Overflow not possible: value <= totalSupply or value <= fromBalance <= totalSupply.
                totalSupply -= amount;
            }
        } else {
            unchecked {
                // Overflow not possible: balance + value is at most totalSupply, which we know fits into a uint256.
                balanceOf[to] += amount;
            }
        }

        emit ERC20Transfer(from, to, amount);
        return true;
    }

    /// @notice Internal function for fractional transfers
    function _nftTransfer(address from, address to, uint256 tokenId) internal returns (address) {
        if (from != _ownerOf[tokenId]) {
            revert InvalidSender();
        }

        if (
            from != address(0) && msg.sender != from && !isApprovedForAll[from][msg.sender]
                && msg.sender != getApproved[tokenId]
        ) {
            revert Unauthorized();
        }

        delete getApproved[tokenId];

        // Execute the update
        if (from != address(0)) {
            unchecked {
                erc721BalanceOf[from] -= 1;
            }
        }

        if (to != address(0)) {
            unchecked {
                erc721BalanceOf[to] += 1;
            }
        }

        _ownerOf[tokenId] = to;

        emit Transfer(from, to, tokenId);

        return from;
    }

    // Internal utility logic
    function _getUnit() internal view returns (uint256) {
        return unit * 10 ** decimals;
    }

    function _mint(address to) internal virtual returns (uint256 id) {
        if (to == address(0)) {
            revert InvalidRecipient();
        }

        if (minted == nftTotalSupply) {
            revert ExceedMaxNftSupply();
        }

        id = minted;

        unchecked {
            minted++;
        }

        if (_ownerOf[id] != address(0)) {
            revert AlreadyExists();
        }

        _nftTransfer(address(0), to, id);
    }

    function _burn(address account, uint256 amountOrId) internal virtual {
        if (account == address(0)) {
            revert InvalidSender();
        }

        if (_isValidTokenId(amountOrId)) {
            _nftTransfer(account, address(0), amountOrId);
        } else {
            _transfer(account, address(0), amountOrId);
        }
    }

    function _setNameSymbol(string memory _name, string memory _symbol) internal {
        name = _name;
        symbol = _symbol;
    }
}
