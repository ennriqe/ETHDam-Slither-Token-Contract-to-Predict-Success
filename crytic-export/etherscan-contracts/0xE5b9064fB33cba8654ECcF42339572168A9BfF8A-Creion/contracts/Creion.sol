// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import 'erc721a-upgradeable/contracts/ERC721AUpgradeable.sol';
import 'erc721a-upgradeable/contracts/extensions/ERC721AQueryableUpgradeable.sol';
import 'erc721a-upgradeable/contracts/extensions/ERC721ABurnableUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol';
import '@openzeppelin/contracts/utils/cryptography/MerkleProof.sol';
import {OperatorFilterer} from 'closedsea/src/OperatorFilterer.sol';
import './interface/ICreion.sol';

contract Creion is
  ICreion,
  ERC721AUpgradeable,
  ERC721ABurnableUpgradeable,
  ERC721AQueryableUpgradeable,
  OperatorFilterer,
  OwnableUpgradeable
{
  // =============================================================
  //                           VARIABLES
  // =============================================================

  NFT public nft;
  TeamMint public teamMintSettings;
  string[] public metadata;

  mapping(uint256 => Phases) public phases;
  mapping(address => uint256) public presaleWalletMinted;
  mapping(address => uint256) public fcfsWalletMinted;
  mapping(address => uint256) public publicWalletMinted;

  // =============================================================
  //                            EVENTS
  // =============================================================
  event PresaleMinted(address indexed user, uint256 qty);
  event FCFSMinted(address indexed user, uint256 qty);
  event PublicMinted(address indexed user, uint256 qty);
  event Claimed(address indexed user, uint256 qty);
  event Refunded(address indexed user, uint256 amount);

  // =============================================================
  //                           MODIFIERS
  // =============================================================
  modifier onlyPresaleList(bytes32[] memory _proof, uint256 _qty) {
    // Check if phase is active
    if (!phases[0].isActive) revert PhaseNotActive('presale');

    // Validate if the user is whitelisted
    bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
    if (!(MerkleProof.verify(_proof, nft.presaleMerkleRoot, leaf)))
      revert NotWhitelisted(msg.sender);

    // Check if wallet balance is sufficient
    if ((phases[0].price * _qty) > msg.sender.balance)
      revert InsufficientWalletBalance(msg.sender.balance);

    // Check if the total phase supply is not exceeded
    if ((phases[0].currentSupply + _qty) > phases[0].maxSupply)
      revert PhaseSupplyExceeded(phases[0].maxSupply);

    // Check if user has already exceeded the max mint per wallet
    if ((presaleWalletMinted[msg.sender] + _qty) > phases[0].maxMintPerTx)
      revert PhaseWalletMaxMintExceeded(
        phases[0].maxMintPerTx,
        presaleWalletMinted[msg.sender]
      );

    // Check if payment is sufficient
    if ((phases[0].price * _qty) != msg.value)
      revert InsufficientPayment(phases[0].price, msg.value);

    _;
  }

  modifier onlyFcfsPhase(bytes32[] memory _proof, uint256 _qty) {
    // Check if phase is active
    if (!phases[1].isActive) revert PhaseNotActive('FCFS');

    // Validate if the user trying to mint is whitelisted
    bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
    if (!(MerkleProof.verify(_proof, nft.fcfsMerkleRoot, leaf)))
      revert NotWhitelisted(msg.sender);

    // Check if wallet balance is sufficient
    if ((phases[1].price * _qty) > msg.sender.balance)
      revert InsufficientWalletBalance(msg.sender.balance);

    // gets the total the max supply for the FCFS phase, adds the remaining supply from the presale phase
    uint256 totalMaxSupply = (phases[0].maxSupply - phases[0].currentSupply) +
      phases[1].maxSupply;

    // Check if the total supply is not exceeded
    if ((phases[1].currentSupply + _qty) > totalMaxSupply)
      revert PhaseSupplyExceeded(totalMaxSupply);

    // Check if user has already exeeded the max mint per wallet
    if (fcfsWalletMinted[msg.sender] + _qty > phases[1].maxMintPerTx)
      revert PhaseWalletMaxMintExceeded(
        phases[1].maxMintPerTx,
        fcfsWalletMinted[msg.sender]
      );

    // Check if payment is sufficient
    if ((phases[1].price * _qty) != msg.value)
      revert InsufficientPayment((phases[1].price * _qty), msg.value);

    _;
  }

  modifier onlyPublicPhase(uint256 _qty) {
    // Check if phase is active
    if (!phases[2].isActive) revert PhaseNotActive('public');

    // Check if wallet balance is sufficient
    if ((phases[2].price * _qty) > msg.sender.balance)
      revert InsufficientWalletBalance(msg.sender.balance);

    // Check if user has already exceeded the max mint per wallet
    if (publicWalletMinted[msg.sender] + _qty > phases[2].maxMintPerTx)
      revert PhaseWalletMaxMintExceeded(
        phases[2].maxMintPerTx,
        publicWalletMinted[msg.sender]
      );

    // Check if payment is sufficient
    if ((phases[2].price * _qty) != msg.value)
      revert InsufficientPayment((phases[2].price * _qty), msg.value);

    _;
  }

  modifier publicClaimable() {
    // Check if claim is enabled
    if (!nft.isClaimable) revert ClaimNotEnabled();

    // Check if user has already claimed
    if (publicWalletMinted[msg.sender] == 0) revert NoClaimableNFT();

    // Check if mint is disabled
    if (nft.isMintEnabled) revert MintNotDisabled();

    _;
  }

  modifier mintable() {
    // Check if mint is enabled
    if (!nft.isMintEnabled) revert MintNotEnabled();

    // Check if claim is disabled
    if (nft.isClaimable) revert ClaimNotDisabled();

    _;
  }

  // =============================================================
  //                          CONSTRUCTOR
  // =============================================================

  function initialize() public initializer initializerERC721A {
    __ERC721A_init('Creion', 'CREION');
    __Ownable_init(msg.sender);
  }

  // =============================================================
  //                           MINT LOGIC
  // =============================================================

  /**
   * @param _proof an array of bytes32 values that represent the merkle proof to verify the user
   * @dev This function is used to mint the NFTs for the presale phase
   */
  function presaleMint(
    bytes32[] memory _proof,
    uint256 _qty
  ) public payable mintable onlyPresaleList(_proof, _qty) {
    phases[0].currentSupply += _qty;
    presaleWalletMinted[msg.sender] += _qty;

    (bool success, ) = payable(address(this)).call{
      value: phases[0].price * _qty
    }('');
    if (!success) revert InsufficientWalletBalance(msg.sender.balance);
    _mint(msg.sender, _qty);

    emit PresaleMinted(msg.sender, _qty);
  }

  /**
   * @param _qty number of tokens that user wants to mint
   * @dev This function is used to mint the NFTs for the FCFS phase
   */
  function fcfsMint(
    bytes32[] memory _proof,
    uint256 _qty
  ) public payable mintable onlyFcfsPhase(_proof, _qty) {
    phases[1].currentSupply += _qty;
    fcfsWalletMinted[msg.sender] += _qty;

    (bool success, ) = payable(address(this)).call{
      value: phases[1].price * _qty
    }('');
    if (!success) revert InsufficientWalletBalance(msg.sender.balance);
    _mint(msg.sender, _qty);

    emit FCFSMinted(msg.sender, _qty);
  }

  /**
   * @param _qty number of tokens that user wants to mint
   * @dev This function is used to mint the NFTs for the public phase
   */
  function publicMint(
    uint256 _qty
  ) public payable mintable onlyPublicPhase(_qty) {
    phases[2].currentSupply += _qty;
    publicWalletMinted[msg.sender] += _qty;

    (bool success, ) = payable(address(this)).call{
      value: phases[2].price * _qty
    }('');
    if (!success) revert InsufficientWalletBalance(msg.sender.balance);

    emit PublicMinted(msg.sender, _qty);
  }

  /**
   *
   * @param _proof an array of bytes32 values that represent the merkle proof to verify
   * if the user is eligible to claim the NFT
   * @dev This function is used to claim the NFTs for the public phase
   */
  function publicClaim(bytes32[] memory _proof) external publicClaimable {
    bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
    uint256 qty = publicWalletMinted[msg.sender];

    if (
      (MerkleProof.verify(_proof, nft.publicMerkleRoot, leaf)) &&
      ((totalSupply() + qty) <= nft.maxSupply)
    ) {
      publicWalletMinted[msg.sender] = 0;
      _mint(msg.sender, qty);
      emit Claimed(msg.sender, qty);
    } else {
      publicWalletMinted[msg.sender] = 0;
      (bool success, ) = payable(msg.sender).call{value: phases[2].price * qty}(
        ''
      );
      if (!success) revert InsufficientContractBalance(address(this).balance);
      emit Refunded(msg.sender, phases[2].price * qty);
    }
  }

  /**
   * @dev This function is used to mint the NFTs for the team
   */
  function teamMint() external onlyOwner {
    if (teamMintSettings.isMinted) revert TeamMintAlreadyDone();

    _mint(teamMintSettings.teamAddress, teamMintSettings.mintQty);
    teamMintSettings.isMinted = true;
  }

  /**
   * @dev Emergency function to mint the remaining supply for contingency
   */
  function emergencyMint() external onlyOwner {
    uint256 remainingSupply = nft.maxSupply - totalSupply();
    _mint(msg.sender, remainingSupply);
  }

  function withdrawAmount(uint256 _amount) external onlyOwner {
    (bool success, ) = msg.sender.call{value: _amount}('');
    if (!success) revert WithdrawalFailed();
  }

  function withdrawAll() external onlyOwner {
    (bool success, ) = msg.sender.call{value: address(this).balance}('');
    if (!success) revert WithdrawalFailed();
  }

  // =============================================================
  //                            SETTERS
  // =============================================================

  /**
   * @param _nft NFT struct that contains the NFT settings
   * @dev This function is used to set the NFT settings
   */
  function setNFT(NFT memory _nft) public onlyOwner {
    nft = _nft;
  }

  function setPhaseData(
    uint256 _index,
    Phases memory _phase
  ) external onlyOwner {
    phases[_index] = _phase;
  }

  /**
   *
   * @param _phase the phase that will be set as active
   * @dev This function is used to set the active phase
   */
  function setActivePhase(uint256 _phase) external onlyOwner {
    if (_phase == 0) {
      phases[0].isActive = true;
      phases[1].isActive = false;
      phases[2].isActive = false;
    } else if (_phase == 1) {
      phases[0].isActive = false;
      phases[1].isActive = true;
      phases[2].isActive = false;
    } else if (_phase == 2) {
      phases[0].isActive = false;
      phases[1].isActive = false;
      phases[2].isActive = true;
    } else revert PhaseDoesNotExist(_phase);
  }

  /**
   * @param _mintable whether the NFT is mintable or not
   * @dev This function is used to enable/disable the minting of the NFT
   */
  function setMintable(bool _mintable) external onlyOwner {
    nft.isMintEnabled = _mintable;
  }

  /**
   * @param _claimable whether the NFT is claimable or not
   * @dev This function is used to enable/disable the claiming of the NFT
   */
  function setClaimable(bool _claimable) external onlyOwner {
    nft.isClaimable = _claimable;
  }

  /**
   * @param _metadata an array of strings that contains the metadata for each phase
   * @dev This function is used to set the metadata for each phase
   */
  function setMetadata(string[] memory _metadata) external onlyOwner {
    metadata = _metadata;
  }

  /**
   * @param teamAddress the new address that the team mint will be sent to
   * @dev This function is used to set the new team mint address
   */
  function setTeamAddress(address teamAddress) external onlyOwner {
    teamMintSettings.teamAddress = teamAddress;
  }

  /**
   * @param _qty the quantity of NFTs that the team can mint
   * @dev This function is used to set the quantity of NFTs that the team can mint
   */
  function setTeamMintQty(uint256 _qty) external onlyOwner {
    teamMintSettings.mintQty = _qty;
  }

  /**
   * @param _value whether the NFT is claimable or not
   * @dev This function is used to enable/disable the transferring of the NFT
   */
  function setTransferable(bool _value) external onlyOwner {
    nft.isTransferable = _value;
  }

  /**
   * @param _phase the phase that will be set as the reveal phase
   * @dev This function is used to set the reveal phase
   */
  function setRevealPhase(uint256 _phase) external onlyOwner {
    nft.revealPhase = _phase;
  }

  function setPhaseMerkleRoot(
    uint256 _phase,
    bytes32 _merkleRoot
  ) external onlyOwner {
    if (_phase == 0) {
      nft.presaleMerkleRoot = _merkleRoot;
    } else if (_phase == 1) {
      nft.fcfsMerkleRoot = _merkleRoot;
    } else if (_phase == 2) {
      nft.publicMerkleRoot = _merkleRoot;
    } else revert PhaseDoesNotExist(_phase);
  }

  // =============================================================
  //                            GETTERS
  // =============================================================

  // =============================================================
  //                            OVERRIDE
  // =============================================================

  function tokenURI(
    uint256 tokenId
  )
    public
    view
    virtual
    override(IERC721AUpgradeable, ERC721AUpgradeable)
    returns (string memory)
  {
    if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

    if (nft.revealPhase == 0) {
      return metadata[0];
    }

    string memory baseURI = bytes(metadata[nft.revealPhase]).length != 0
      ? string(
        abi.encodePacked(
          metadata[nft.revealPhase],
          '/',
          _toString(tokenId),
          '.json'
        )
      )
      : '';

    return baseURI;
  }

  // =============================================================
  //                        FALLBACK/RECEIVE
  // =============================================================
  receive() external payable {}

  // =============================================================
  //                        OPERATOR FILTERER
  // =============================================================

  /**
   * Overridden setApprovalForAll with operator filtering.
   */
  function setApprovalForAll(
    address operator,
    bool approved
  )
    public
    override(IERC721AUpgradeable, ERC721AUpgradeable)
    onlyAllowedOperatorApproval(operator)
  {
    if (!nft.isTransferable) revert ListingNotEnabled();
    super.setApprovalForAll(operator, approved);
  }

  /**
   * Overridden approve with operator filtering.
   */
  function approve(
    address operator,
    uint256 tokenId
  )
    public
    payable
    override(IERC721AUpgradeable, ERC721AUpgradeable)
    onlyAllowedOperatorApproval(operator)
  {
    if (!nft.isTransferable) revert ListingNotEnabled();
    super.approve(operator, tokenId);
  }

  /**
   * Overridden transferFrom with operator filtering. For ERC721A, this will also add
   * operator filtering for both safeTransferFrom functions.
   */
  function transferFrom(
    address from,
    address to,
    uint256 tokenId
  )
    public
    payable
    override(IERC721AUpgradeable, ERC721AUpgradeable)
    onlyAllowedOperator(from)
  {
    if (!nft.isTransferable) revert TransferNotEnabled();
    super.transferFrom(from, to, tokenId);
  }

  /**
   * Owner-only function to toggle operator filtering.
   * @param value Whether operator filtering is on/off.
   */
  function setOperatorFilteringEnabled(bool value) public onlyOwner {
    nft.operatorFilteringEnabled = value;
  }

  function _operatorFilteringEnabled() internal view override returns (bool) {
    return nft.operatorFilteringEnabled;
  }
}
