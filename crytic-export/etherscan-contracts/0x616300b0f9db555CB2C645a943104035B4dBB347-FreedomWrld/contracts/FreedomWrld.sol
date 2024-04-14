// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./DN404.sol";
import "./DN404Mirror.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";

interface FreedomPresale {
    function enteredAmount(address) external view returns(uint256);
}

contract FreedomWrld is DN404, Ownable, ReentrancyGuard, Pausable {
    bool public IS_PUBLIC_MINT_LIVE = false;
    bool public IS_WHITELIST_MINT_LIVE = false;
    bool public IS_CLAIM_LIVE = false;

    uint256 public PUBLIC_MINT_PRICE_PER_STEP;
    uint256 public WHITELIST_MINT_PRICE_PER_STEP;

    uint256 public MINT_STEP = 10 ** 17; // 0.1

    uint256 public MAX_TOTAL_SUPPLY = 6000 * _unit();

    uint256 public AVAILABLE_WHITELIST_MINT_SUPPLY;

    uint256 public PUBLIC_MINT_MAX_PER_WALLET = 4 * _unit();

    bytes32 public WHITELIST_MINT_MERKLE_ROOT = 0x0;
    bytes32 public CLAIM_MERKLE_ROOT = 0x0;

    struct Wallet {
        uint256 publicMints;
        uint256 whitelistMints;
        uint256 partnerClaims;
        uint256 presaleClaims;
    }

    mapping(address => Wallet) public wallets;

    mapping(address => bool) public unpausablePerAddress;

    address private _PRESALE_ADDRESS_1;
    address private _PRESALE_ADDRESS_2;

    string public baseURI = "";

    bool private _pausedApprovalsAndTransfers = true;

    constructor(
        uint256 _publicMintPricePerStep,
        uint256 _whitelistMintPricePerStep,
        uint256 _availableWhitelistMintSupply,
        uint256 _initialTokenSupply,
        address _presaleAddress1,
        address _presaleAddress2
    ) Ownable(msg.sender) {
        unpausablePerAddress[msg.sender] = true;

        PUBLIC_MINT_PRICE_PER_STEP = _publicMintPricePerStep;
        WHITELIST_MINT_PRICE_PER_STEP = _whitelistMintPricePerStep;

        AVAILABLE_WHITELIST_MINT_SUPPLY = _availableWhitelistMintSupply;

        _PRESALE_ADDRESS_1 = _presaleAddress1;
        _PRESALE_ADDRESS_2 = _presaleAddress2;

        address mirror = address(new DN404Mirror(msg.sender));

        _initializeDN404(_initialTokenSupply, msg.sender, mirror);
    }

    function name() public pure override returns (string memory) {
        return "FreedomWrld";
    }

    function symbol() public pure override returns (string memory) {
        return "FREE";
    }

    function mintPublic(uint256 _amount) external payable nonReentrant {
        require(IS_PUBLIC_MINT_LIVE, "Public mint not live");
        require(_amount > 0, "Cannot mint zero");
        require(wallets[msg.sender].publicMints > 0 || _amount >= _unit(), "Must mint at least 1");
        require(totalSupply() + _amount <= MAX_TOTAL_SUPPLY, "Max total supply reached");
        require(wallets[msg.sender].publicMints + _amount <= PUBLIC_MINT_MAX_PER_WALLET, "Max public mints per wallet reached");

        require(_amount % MINT_STEP == 0, "Incorrect mint amount");
        uint256 amountSteps = _amount / MINT_STEP;
        require(amountSteps * PUBLIC_MINT_PRICE_PER_STEP <= msg.value, "Not enough ETH");

        unchecked {
            wallets[msg.sender].publicMints += _amount;
        }

        _mint(msg.sender, _amount);
    }

    function mintWhitelist(uint256 _amount, uint256 _maxAmount, bytes32[] calldata _proof) external payable nonReentrant {
        require(IS_WHITELIST_MINT_LIVE, "Whitelist mint not live");

        bytes32 proofLeaf = keccak256(abi.encodePacked(msg.sender, _maxAmount));
        require(MerkleProof.verifyCalldata(_proof, WHITELIST_MINT_MERKLE_ROOT, proofLeaf), "Not allowed to mint from whitelist");

        require(_amount > 0, "Cannot mint zero");
        require(wallets[msg.sender].whitelistMints > 0 || _amount >= _unit(), "Must mint at least 1");
        require(totalSupply() + _amount <= MAX_TOTAL_SUPPLY, "Max total supply reached");
        require(AVAILABLE_WHITELIST_MINT_SUPPLY > 0, "Max whitelist supply reached");
        require(wallets[msg.sender].whitelistMints + _amount <= _maxAmount, "Max whitelist amount reached");

        require(_amount % MINT_STEP == 0, "Incorrect mint amount");
        uint256 amountSteps = _amount / MINT_STEP;
        require(amountSteps * WHITELIST_MINT_PRICE_PER_STEP <= msg.value, "Not enough ETH");

        unchecked {
            wallets[msg.sender].whitelistMints += _amount;
            AVAILABLE_WHITELIST_MINT_SUPPLY -= _amount;
        }

        _mint(msg.sender, _amount);
    }

    function claimPartner(uint256 _amount, uint256 _maxAmount, bytes32[] calldata _proof) external nonReentrant {
        require(IS_CLAIM_LIVE, "Claim not live");

        bytes32 proofLeaf = keccak256(abi.encodePacked(msg.sender, _maxAmount));
        require(MerkleProof.verifyCalldata(_proof, CLAIM_MERKLE_ROOT, proofLeaf), "Not allowed to claim");

        require(totalSupply() + _amount <= MAX_TOTAL_SUPPLY, "Max total supply reached");
        require(wallets[msg.sender].partnerClaims + _amount <= _maxAmount, "Max whitelist amount reached");

        unchecked {
            wallets[msg.sender].partnerClaims += _amount;
        }

        _mint(msg.sender, _amount);
    }

    function claimPresale(uint256 _amount) external nonReentrant {
        require(IS_CLAIM_LIVE, "Claim not live");

        FreedomPresale presale1 = FreedomPresale(_PRESALE_ADDRESS_1);
        FreedomPresale presale2 = FreedomPresale(_PRESALE_ADDRESS_2);
        uint256 presaleAmount1 = presale1.enteredAmount(msg.sender);
        uint256 presaleAmount2 = presale2.enteredAmount(msg.sender);
        uint256 maxAmount = (presaleAmount1 + presaleAmount2) * _unit();

        require(maxAmount > 0, "Not part of presale");
        require(wallets[msg.sender].presaleClaims + _amount <= maxAmount, "Max available presale amount reached");
        require(totalSupply() + _amount <= MAX_TOTAL_SUPPLY, "Max total supply reached");

        unchecked {
            wallets[msg.sender].presaleClaims += _amount;
        }

        _mint(msg.sender, _amount);
    }

    function setPublicMintMaxPerWallet(uint256 _newValue) external onlyOwner {
        PUBLIC_MINT_MAX_PER_WALLET = _newValue;
    }

    function setAvailableWhitelistMintSupply(uint256 _newValue) external onlyOwner {
        AVAILABLE_WHITELIST_MINT_SUPPLY = _newValue;
    }

    function setPublicMintPrice(uint256 _newValue) external onlyOwner {
        PUBLIC_MINT_PRICE_PER_STEP = _newValue;
    }

    function setWhitelistMintPrice(uint256 _newValue) external onlyOwner {
        WHITELIST_MINT_PRICE_PER_STEP = _newValue;
    }

    function togglePublicMintIsLive() external onlyOwner {
        IS_PUBLIC_MINT_LIVE = !IS_PUBLIC_MINT_LIVE;
    }

    function toggleWhitelistMintIsLive() external onlyOwner {
        IS_WHITELIST_MINT_LIVE = !IS_WHITELIST_MINT_LIVE;
    }

    function toggleClaimIsLive() external onlyOwner {
        IS_CLAIM_LIVE = !IS_CLAIM_LIVE;
    }

    function setWhitelistMintMerkleRoot(bytes32 _newValue) external onlyOwner {
        WHITELIST_MINT_MERKLE_ROOT = _newValue;
    }

    function setClaimMerkleRoot(bytes32 _newValue) external onlyOwner {
        CLAIM_MERKLE_ROOT = _newValue;
    }

    function setBaseURI(string calldata _newValue) external onlyOwner {
        baseURI = _newValue;
    }

    function setMintStep(uint256 _newValue) external onlyOwner {
        MINT_STEP = _newValue;
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory result) {
        if (bytes(baseURI).length != 0) {
            result = string(abi.encodePacked(baseURI, Strings.toString(tokenId)));
        }
    }

    function withdrawEthBalance() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    function togglePausedApprovalsAndTransfers() external onlyOwner {
        _pausedApprovalsAndTransfers = !_pausedApprovalsAndTransfers;
    }

    function setUnpausableAddress(address _newValue, bool unpausable) external onlyOwner {
        unpausablePerAddress[_newValue] = unpausable;
    }

    function paused() public view override returns (bool) {
        return _pausedApprovalsAndTransfers && !unpausablePerAddress[msg.sender];
    }

    function approve(address spender, uint256 amount) public override whenNotPaused returns (bool) {
        return super.approve(spender, amount);
    }

    function transfer(address to, uint256 amount) public override whenNotPaused returns (bool) {
        return super.transfer(to, amount);
    }

    function transferFrom(address from, address to, uint256 amount) public override whenNotPaused returns (bool) {
        return super.transferFrom(from, to, amount);
    }
}
