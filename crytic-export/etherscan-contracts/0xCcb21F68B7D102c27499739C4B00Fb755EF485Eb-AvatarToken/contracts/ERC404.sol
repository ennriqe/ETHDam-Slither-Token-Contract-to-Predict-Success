//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {PausableUpgradeable} from "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import {ReentrancyGuardUpgradeable} from "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {CircleQueue} from "./CircleQueue.sol";

abstract contract ERC721Receiver {
    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external virtual returns (bytes4) {
        return ERC721Receiver.onERC721Received.selector;
    }
}

/// @notice ERC404
///         A gas-efficient, mixed ERC20 / ERC721 implementation
///         with native liquidity and fractionalization.
///
///         This is an experimental standard designed to integrate
///         with pre-existing ERC20 / ERC721 support as smoothly as
///         possible.
///
/// @dev    In order to support full functionality of ERC20 and ERC721
///         supply assumptions are made that slightly constraint usage.
///         Ensure decimals are sufficiently large (standard 18 recommended)
///         as ids are effectively encoded in the lowest range of amounts.
///
///         NFTs are spent on ERC20 functions in a FILO queue, this is by
///         design.
///
contract ERC404 is
    PausableUpgradeable,
    ReentrancyGuardUpgradeable,
    OwnableUpgradeable
{
    event ERC20Transfer(
        address indexed from,
        address indexed to,
        uint256 amount
    );

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 amount
    );
    event Transfer(
        address indexed from,
        address indexed to,
        uint256 indexed id
    );
    event ERC721Approval(
        address indexed owner,
        address indexed spender,
        uint256 indexed id
    );
    event ApprovalForAll(
        address indexed owner,
        address indexed operator,
        bool approved
    );

    event BaseTokenURIUpdated(address indexed owner, string indexed tokenURI);

    // Errors
    error NotFound();
    error AlreadyExists();
    error InvalidRecipient();
    error InvalidSender();
    error UnsafeRecipient();

    // Metadata
    /// @dev Token name
    string public name;

    /// @dev Token symbol
    string public symbol;

    /// @dev Decimals for fractional representation
    uint8 public decimals;

    /// @dev power for fractional representation
    uint8 public power;

    /// @dev Total supply in fractionalized representation
    uint256 public totalSupply;

    uint256 public maxCount;

    /// @dev Current mint counter, monotonically increasing to ensure accurate ownership
    uint256 public minted;

    // Mappings
    /// @dev Balance of user in fractional representation
    mapping(address => uint256) public balanceOf;

    /// @dev Allowance of user in fractional representation
    mapping(address => mapping(address => uint256)) public allowance;

    /// @dev Approval in native representaion
    mapping(uint256 => address) public getApproved;

    /// @dev Approval for all in native representation
    mapping(address => mapping(address => bool)) public isApprovedForAll;

    /// @dev Owner of id in native representation
    mapping(uint256 => address) internal _ownerOf;

    /// @dev Array of owned ids in native representation
    mapping(address => uint256[]) internal _owned;

    /// @dev Tracks indices for the _owned mapping
    mapping(uint256 => uint256) internal _ownedIndex;

    string internal dataURI;
    string internal baseTokenURI;
    uint256 public lockTime;

    // Assuming the existence of a vault mechanism within the contract
    // FIFO queue for vault
    CircleQueue public vault;

    // only use to clear lock
    function clearLock() public onlyOwner {
        lockTime = 0;
    }

    function setDataURI(string memory _dataURI) public onlyOwner {
        dataURI = _dataURI;
    }

    function setTokenURI(string memory _tokenURI) public onlyOwner {
        baseTokenURI = _tokenURI;
        emit BaseTokenURIUpdated(msg.sender, _tokenURI);
    }

    function tokenURI(uint256 id) public view virtual returns (string memory) {
        if (bytes(baseTokenURI).length == 0) {
            return dataURI;
        }
        uint256 tokenId = id % maxCount;
        return
            string(
                abi.encodePacked(
                    baseTokenURI,
                    Strings.toString(tokenId),
                    ".json"
                )
            );
    }

    //can only set one time
    function initialize(
        string memory _name,
        string memory _symbol,
        uint8 _decimals,
        uint256 _totalNativeSupply,
        uint8 _power,
        uint256 _maxSupply,
        address _vault,
        uint256 _lockTime
    ) external initializer {
        __Pausable_init();
        __ReentrancyGuard_init();
        __Ownable_init();

        _pause();

        name = _name;
        symbol = _symbol;
        decimals = _decimals;
        power = _power;
        totalSupply = _totalNativeSupply * (10 ** (_decimals + _power));
        maxCount = _maxSupply;
        vault = CircleQueue(_vault);
        lockTime = _lockTime;
    }

    /// @notice Function to find owner of a given native token
    function ownerOf(uint256 id) public view virtual returns (address owner) {
        owner = _ownerOf[id];

        if (owner == address(0)) {
            revert NotFound();
        }
    }

    // @notice Function to get the id of the token at a given index and owner
    function tokenOfOwnerByIndex(
        address owner,
        uint256 index
    ) public view virtual returns (uint256) {
        require(
            index < _owned[owner].length,
            "ERC404: owner index out of bounds"
        );
        return _owned[owner][index];
    }

    // @notice Function get the total number of NFT owned by a given address
    function balanceOfNFT(address owner) public view virtual returns (uint256) {
        return _owned[owner].length;
    }

    /// @notice Function for token approvals
    /// @dev This function assumes id / native if amount less than or equal to current max id
    function approve(
        address spender,
        uint256 amountOrId
    ) public virtual returns (bool) {
        if (lockTime > 0 && block.timestamp < lockTime) {
            revert("ERC404: Locked for minting");
        }

        if (amountOrId <= maxCount && amountOrId > 0) {
            address owner = _ownerOf[amountOrId];

            if (msg.sender != owner && !isApprovedForAll[owner][msg.sender]) {
                revert("ERC404: Not approved, Not Authorized");
            }

            getApproved[amountOrId] = spender;

            emit Approval(owner, spender, amountOrId);
            emit ERC721Approval(owner, spender, amountOrId);
        } else {
            allowance[msg.sender][spender] = amountOrId;

            emit Approval(msg.sender, spender, amountOrId);
        }

        return true;
    }

    /// @notice Function native approvals
    function setApprovalForAll(address operator, bool approved) public virtual {
        isApprovedForAll[msg.sender][operator] = approved;

        emit ApprovalForAll(msg.sender, operator, approved);
    }

    /// @notice Function for mixed transfers
    /// @dev This function assumes id / native if amount less than or equal to current max id
    function transferFrom(
        address from,
        address to,
        uint256 amountOrId
    ) public virtual nonReentrant {
        if (lockTime > 0 && block.timestamp < lockTime) {
            revert("ERC404: Locked for minting");
        }
        if (amountOrId <= maxCount && _ownerOf[amountOrId] == from) {
            if (to == address(0)) {
                revert InvalidRecipient();
            }

            if (
                msg.sender != from &&
                !isApprovedForAll[from][msg.sender] &&
                msg.sender != getApproved[amountOrId]
            ) {
                revert("ERC404: Not approved, Not Authorized");
            }

            balanceOf[from] -= _getUnit();

            unchecked {
                balanceOf[to] += _getUnit();
            }

            _ownerOf[amountOrId] = to;
            delete getApproved[amountOrId];

            // update _owned for sender
            uint256 updatedId = _owned[from][_owned[from].length - 1];
            _owned[from][_ownedIndex[amountOrId]] = updatedId;
            // pop
            _owned[from].pop();
            // update index for the moved id
            _ownedIndex[updatedId] = _ownedIndex[amountOrId];
            // push token to to owned
            _owned[to].push(amountOrId);
            // update index for to owned
            _ownedIndex[amountOrId] = _owned[to].length - 1;

            emit Transfer(from, to, amountOrId);
            emit ERC20Transfer(from, to, _getUnit());
        } else {
            uint256 allowed = allowance[from][msg.sender];

            if (allowed != type(uint256).max && allowed >= amountOrId)
                allowance[from][msg.sender] = allowed - amountOrId;

            _transfer(from, to, amountOrId);
        }
    }

    /// @notice Function for fractional transfers
    function transfer(
        address to,
        uint256 amount
    ) public virtual nonReentrant returns (bool) {
        return _transfer(msg.sender, to, amount);
    }

    /// @notice Function for native transfers with contract support
    function safeTransferFrom(
        address from,
        address to,
        uint256 id
    ) public virtual {
        transferFrom(from, to, id);

        if (
            to.code.length != 0 &&
            ERC721Receiver(to).onERC721Received(msg.sender, from, id, "") !=
            ERC721Receiver.onERC721Received.selector
        ) {
            revert UnsafeRecipient();
        }
    }

    /// @notice Function for native transfers with contract support and callback data
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        bytes calldata data
    ) public virtual {
        transferFrom(from, to, id);

        if (
            to.code.length != 0 &&
            ERC721Receiver(to).onERC721Received(msg.sender, from, id, data) !=
            ERC721Receiver.onERC721Received.selector
        ) {
            revert UnsafeRecipient();
        }
    }

    /// @notice Internal function for fractional transfers without mint / burn
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual returns (bool) {
        if (lockTime > 0 && block.timestamp < lockTime) {
            revert("ERC404: Locked for minting");
        }

        require(balanceOf[from] >= amount, "ERC404: Insufficient balance");

        uint256 unit = _getUnit();
        uint256 balanceBeforeSender = balanceOf[from];
        uint256 balanceBeforeReceiver = balanceOf[to];

        balanceOf[from] -= amount;

        unchecked {
            balanceOf[to] += amount;
        }

        uint256 left = amount;

        uint256 nft_to_transfer = 0;
        if (amount >= unit) {
            nft_to_transfer =
                (balanceOf[to] / unit) -
                (balanceBeforeReceiver / unit);
            //One nft must be transfer from vault to receiver
            if (nft_to_transfer * unit > amount) {
                nft_to_transfer -= 1;
            }
            for (uint256 i = 0; i < nft_to_transfer; i++) {
                uint256 id = _owned[from][_owned[from].length - 1];
                _transferNFT(from, to, id);                
            }
            left = amount - nft_to_transfer * unit;
        }
        // If `from` has NFTs to deposit and `left` amount is not sufficient for a full NFT
        if (
            left > 0 &&
            left < unit &&
            (_owned[from].length > 0) &&
            ((balanceBeforeSender / unit) !=
                ((balanceBeforeSender - left) / unit))
        ) {
            uint256 id = _owned[from][_owned[from].length - 1];
            approve(address(this), id);
            // Add the NFT to the vault queue
            vault.enqueue(id, from, block.timestamp);
            // Transfer the NFT to the contract (vault)
            _transferNFT(from, address(this), id);
        }

        if (
            ((balanceOf[to] / unit) >= 1) &&
            (vault.size() > 0) &&
            ((balanceBeforeReceiver / unit) !=
                ((balanceBeforeReceiver + left) / unit))
        ) {
            // Remove the first NFT from the vault queue
            (uint256 id, , ) = vault.dequeue();
            _transferNFT(address(this), to, id);
        }

        emit ERC20Transfer(from, to, amount);
        return true;
    }

    // @notice Internal function for fractional transfers a single NFT
    function _transferNFT(address from, address to, uint256 tokenId) internal {
        delete getApproved[tokenId];

        _ownerOf[tokenId] = to;

        uint256 lastIndex = _owned[from].length - 1;
        uint256 tokenIndex = _ownedIndex[tokenId];
        if (tokenIndex != lastIndex) {
            uint256 lastTokenId = _owned[from][lastIndex];
            _owned[from][tokenIndex] = lastTokenId;
            _ownedIndex[lastTokenId] = tokenIndex;
        }
        _owned[from].pop();
        delete _ownedIndex[tokenId];

        _owned[to].push(tokenId);
        _ownedIndex[tokenId] = _owned[to].length - 1;

        emit Transfer(from, to, tokenId);
    }

    // Internal utility logic
    function _getUnit() internal view returns (uint256) {
        return 10 ** (power + decimals);
    }

    function _mint(address to) internal virtual {
        if (to == address(0)) {
            revert InvalidRecipient();
        }

        unchecked {
            minted++;
        }

        uint256 id = minted;

        if (_ownerOf[id] != address(0)) {
            revert AlreadyExists();
        }

        _ownerOf[id] = to;
        _owned[to].push(id);
        _ownedIndex[id] = _owned[to].length - 1;

        emit Transfer(address(0), to, id);
    }

    function _burn(address from) internal virtual {
        if (from == address(0)) {
            revert InvalidSender();
        }

        uint256 id = _owned[from][_owned[from].length - 1];
        _owned[from].pop();
        delete _ownedIndex[id];
        delete _ownerOf[id];
        delete getApproved[id];

        emit Transfer(from, address(0), id);
    }

    function _setNameSymbol(
        string memory _name,
        string memory _symbol
    ) internal {
        name = _name;
        symbol = _symbol;
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }
}
