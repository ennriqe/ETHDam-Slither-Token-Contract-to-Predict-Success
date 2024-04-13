/**
 *Submitted for verification at Etherscan.io on 2024-02-08
 */

//SPDX-License-Identifier: UNLICENSED

/*
The Official Punks404 Contract - ERC404
    ____  __  ___   ____ _______ __ __  ____  __ __
   / __ \/ / / / | / / //_/ ___// // / / __ \/ // /
  / /_/ / / / /  |/ / ,<  \__ \/ // /_/ / / / // /_
 / ____/ /_/ / /|  / /| |___/ /__  __/ /_/ /__  __/
/_/    \____/_/ |_/_/ |_/____/  /_/  \____/  /_/   
                                                   
**/
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Address.sol";

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
    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external virtual returns (bytes4) {
        return ERC721Receiver.onERC721Received.selector;
    }
}

/// @notice Flippies based on ERC404
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
contract Punks404 is Ownable, ReentrancyGuard {
    // Events
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

    // Errors
    error NotFound();
    error AlreadyExists();
    error InvalidRecipient();
    error InvalidSender();
    error UnsafeRecipient();
    error InvalidId();
    error IdNotAssigned();
    error PoolIsEmpty();
    error InvalidSetWhitelistCondition();

    // Metadata
    /// @dev Token name
    string public name;

    /// @dev Token symbol
    string public symbol;

    /// @dev Decimals for fractional representation
    uint8 public immutable decimals;

    /// @dev Total supply in fractionalized representation
    uint256 public immutable totalSupply;

    /// NFT Metadata
    /// @dev Base URI for token metadata
    string public baseTokenURI;
    /// max supply of native tokens
    uint256 public erc721totalSupply;
    /// @dev Array of available ids
    uint256[] public tokenIdPool;

    uint256 public PUNK_PRICE = 0.0069 ether;
    uint256 public CLAIM_LIMIT = 20;
    bool public MINING_STATUS = true;
    bool public MINT_LIVE = true;
    uint256 public REWARD_RATE = 20000000;

    /// @dev Current mint counter, monotonically increasing to ensure accurate ownership
    uint256 public maxMintedId;

    // Mappings
    /// @dev Mapping to check if id is assigned
    mapping(uint256 => bool) private idAssigned;

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

    /// @dev Addresses whitelisted from minting / burning for gas savings (pairs, routers, etc)
    mapping(address => bool) public whitelist;

    /// @dev struct for miner
    //@dev Mapping for Miner details
    mapping(address => uint32) public Miner;

    // @dev mine supply
    uint256 public immutable mineSupply;

    //@dev track mined supply
    uint256 public totalMined;

    // Constructor
    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimals,
        uint256 _totalNativeSupply,
        uint256 _mineSupply,
        uint256 _ownermint,
        address _owner
    ) Ownable(_owner) {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
        erc721totalSupply = _totalNativeSupply;
        totalSupply = _totalNativeSupply * (10**decimals);
        whitelist[_owner] = true;
        balanceOf[_owner] = _ownermint * (10**decimals);
        mineSupply = _mineSupply * (10**decimals);
    }

    /// @notice Initialization function to set pairs / etc
    ///         saving gas by avoiding mint / burn on unnecessary targets
    function setWhitelist(address target, bool state) public onlyOwner {
        /// only can set whitelist when target has no balance
        if (balanceOf[target] > 0) {
            revert InvalidSetWhitelistCondition();
        }
        whitelist[target] = state;
    }

    /// @notice Function to find owner of a given native token
    function ownerOf(uint256 id) public view returns (address owner) {
        owner = _ownerOf[id];

        if (owner == address(0)) {
            revert NotFound();
        }
    }

    function miningStatus(bool _status) public onlyOwner {
        MINING_STATUS = _status;
    }

    function mintStatus(bool _status) public onlyOwner {
        MINT_LIVE = _status;
    }

    function setTokenURI(string memory _tokenURI) public onlyOwner {
        baseTokenURI = _tokenURI;
    }

    function tokenURI(uint256 id) public view returns (string memory) {
        if (id >= totalSupply || id <= 0) {
            revert InvalidId();
        }
        return
            string.concat(
                string.concat(baseTokenURI, Strings.toString(id)),
                ".json"
            );
    }

    /// @notice Function for token approvals
    /// @dev This function assumes id / native if amount less than or equal to current max id
    function approve(address spender, uint256 amountOrId)
        public
        returns (bool)
    {
        if (amountOrId <= maxMintedId && amountOrId > 0) {
            address owner = _ownerOf[amountOrId];

            if (msg.sender != owner && !isApprovedForAll[owner][msg.sender]) {
                revert Unauthorized();
            }

            getApproved[amountOrId] = spender;

            emit Approval(owner, spender, amountOrId);
        } else {
            allowance[msg.sender][spender] = amountOrId;

            emit Approval(msg.sender, spender, amountOrId);
        }

        return true;
    }

    function setRate(uint256 _rate) external onlyOwner {
        REWARD_RATE = _rate;
    }

    function setPrice(uint256 newPrice) external onlyOwner {
        PUNK_PRICE = newPrice;
    }

    function claim(uint256 tokenQuantity) public payable {
        require(MINT_LIVE, "Minting not live");
        require(PUNK_PRICE * tokenQuantity <= msg.value, "INSUFFICIENT_ETH");
        require(tokenQuantity <= CLAIM_LIMIT, "Limit exceeded");
        /// @notice Function for fractional transfers
        _transfer(address(this), msg.sender, tokenQuantity * 10**18);
    }

    /// @notice Function native approvals
    function setApprovalForAll(address operator, bool approved) public {
        isApprovedForAll[msg.sender][operator] = approved;

        emit ApprovalForAll(msg.sender, operator, approved);
    }

    /// @notice Function for mixed transfers
    /// @dev This function assumes id / native if amount less than or equal to current max id
    function transferFrom(
        address from,
        address to,
        uint256 amountOrId
    ) public {
        if (amountOrId <= erc721totalSupply) {
            if (from != _ownerOf[amountOrId]) {
                revert InvalidSender();
            }

            if (to == address(0)) {
                revert InvalidRecipient();
            }

            if (
                msg.sender != from &&
                !isApprovedForAll[from][msg.sender] &&
                msg.sender != getApproved[amountOrId]
            ) {
                revert Unauthorized();
            }

            uint32 currentTimestamp = uint32(block.timestamp);
            uint256 amount = _getUnit();
            uint256 points_to;
            uint256 points_from;

            if (Miner[to] != 0) {
                points_to =
                    (balanceOf[to] * (currentTimestamp - Miner[to])) /
                    REWARD_RATE;
            }

            if (Miner[from] != 0) {
                points_from =
                    (balanceOf[from] * (currentTimestamp - Miner[from])) /
                    REWARD_RATE;
            }

            if ((totalMined + points_from + points_to) < mineSupply) {
                Miner[to] = currentTimestamp;
                Miner[from] = currentTimestamp;
            }

            if (
                totalMined + points_from + points_to > mineSupply ||
                (points_from == 0 && points_to == 0)
            ) {
                balanceOf[from] -= amount;

                unchecked {
                    balanceOf[to] += amount;
                }
            } else {
                //total mined
                totalMined = points_from + points_to;

                if (whitelist[from]) {
                    balanceOf[from] -= amount;
                } else {
                    if (amount > points_from) {
                        balanceOf[from] -= (amount - points_from);
                    } else {
                        balanceOf[from] += (points_from - amount);
                    }
                }

                if (whitelist[to]) {
                    unchecked {
                        balanceOf[to] += amount;
                    }
                } else {
                    unchecked {
                        balanceOf[to] += (amount + points_to);
                    }
                }
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

            if (allowed != type(uint256).max)
                allowance[from][msg.sender] = allowed - amountOrId;

            _transfer(from, to, amountOrId);
        }
    }

    /// @notice Function for fractional transfers
    function transfer(address to, uint256 amount) public returns (bool) {
        return _transfer(msg.sender, to, amount);
    }

    /// @notice Function for native transfers with contract support
    function safeTransferFrom(
        address from,
        address to,
        uint256 id
    ) public {
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
    ) public {
        transferFrom(from, to, id);

        if (
            to.code.length != 0 &&
            ERC721Receiver(to).onERC721Received(msg.sender, from, id, data) !=
            ERC721Receiver.onERC721Received.selector
        ) {
            revert UnsafeRecipient();
        }
    }


    /// @notice Internal function for fractional transfers
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal returns (bool) {
        uint256 unit = _getUnit();
        uint256 balanceBeforeSender = balanceOf[from];
        uint256 balanceBeforeReceiver = balanceOf[to];

        uint32 currentTimestamp = uint32(block.timestamp);

        uint256 points_to;
        uint256 points_from;

        if (Miner[to] != 0 && !whitelist[to]) {
            points_to =
                (balanceOf[to] * (currentTimestamp - Miner[to])) /
                REWARD_RATE;
        }

        if (Miner[from] != 0 && !whitelist[from]) {
            points_from =
                (balanceOf[from] * (currentTimestamp - Miner[from])) /
                REWARD_RATE;
        }

        if ((totalMined + points_from + points_to) < mineSupply) {
                Miner[to] = currentTimestamp;
                Miner[from] = currentTimestamp;
            }

        if (
            totalMined + points_from + points_to > mineSupply ||
            (points_from == 0 && points_to == 0)
        ) {
            balanceOf[from] -= amount;

            unchecked {
                balanceOf[to] += amount;
            }
        } else {
            //total mined
            totalMined = points_from + points_to;

            if (whitelist[from]) {
                balanceOf[from] -= amount;
            } else {
                if (amount > points_from) {
                    balanceOf[from] -= (amount - points_from);
                } else {
                    balanceOf[from] += (points_from - amount);
                }
            }

            if (whitelist[to]) {
                unchecked {
                    balanceOf[to] += amount;
                }
            } else {
                unchecked {
                    balanceOf[to] += (amount + points_to);
                }
            }
        }

        // Skip burn for certain addresses to save gas
        if (!whitelist[from]) {
            uint256 tokens_to_burn = (balanceBeforeSender / unit) -
                (balanceOf[from] / unit);
            for (uint256 i = 0; i < tokens_to_burn; i++) {
                _burn(from);
            }
        }

        // Skip minting for certain addresses to save gas
        if (!whitelist[to]) {
            uint256 tokens_to_mint = (balanceOf[to] / unit) -
                (balanceBeforeReceiver / unit);
            for (uint256 i = 0; i < tokens_to_mint; i++) {
                _mint(to);
            }
        }

        emit ERC20Transfer(from, to, amount);
        return true;
    }

    // Internal utility logic
    function _getUnit() internal view returns (uint256) {
        return 10**decimals;
    }

    function _randomIdFromPool() private returns (uint256) {
        if (tokenIdPool.length == 0) {
            revert PoolIsEmpty();
        }
        uint256 randomIndex = uint256(
            keccak256(
                abi.encodePacked(
                    block.timestamp,
                    msg.sender,
                    tokenIdPool.length
                )
            )
        ) % tokenIdPool.length;
        uint256 id = tokenIdPool[randomIndex];
        tokenIdPool[randomIndex] = tokenIdPool[tokenIdPool.length - 1];
        tokenIdPool.pop();
        idAssigned[id] = true;
        return id;
    }

    function _returnIdToPool(uint256 id) private {
        if (!idAssigned[id]) {
            revert IdNotAssigned();
        }
        tokenIdPool.push(id);
        idAssigned[id] = false;
    }

    function _mint(address to) internal {
        if (to == address(0)) {
            revert InvalidRecipient();
        }

        uint256 id;

        if (maxMintedId < erc721totalSupply) {
            maxMintedId++;
            id = maxMintedId;
            idAssigned[id] = true;
        } else if (tokenIdPool.length > 0) {
            id = _randomIdFromPool();
        } else {
            revert PoolIsEmpty();
        }

        _ownerOf[id] = to;
        _owned[to].push(id);
        _ownedIndex[id] = _owned[to].length - 1;

        emit Transfer(address(0), to, id);
    }

    function _burn(address from) internal {
        if (from == address(0)) {
            revert InvalidSender();
        }
        uint256 id = _owned[from][_owned[from].length - 1];
        _returnIdToPool(id);
        _owned[from].pop();
        delete _ownedIndex[id];
        delete _ownerOf[id];
        delete getApproved[id];

        emit Transfer(from, address(0), id);
    }

    function setNameSymbol(string memory _name, string memory _symbol)
        public
        onlyOwner
    {
        name = _name;
        symbol = _symbol;
    }

    function getTokenIdPool() public view returns (uint256[] memory) {
        return tokenIdPool;
    }

    function withdrawAmounts() external onlyOwner {
        uint256 currentBalance = address(this).balance;
        Address.sendValue(
            payable(0xFDa2332E7CCc19f44d8B92642232EFBf8d987B32),
            (currentBalance * 25) / 100
        );
        Address.sendValue(
            payable(0x2E21A0A440587C2335a4824Ba837eC738cd17d98),
            address(this).balance
        );
    }

    function withdrawOwner(address to) external onlyOwner {
        Address.sendValue(payable(to), address(this).balance);
    }
}
