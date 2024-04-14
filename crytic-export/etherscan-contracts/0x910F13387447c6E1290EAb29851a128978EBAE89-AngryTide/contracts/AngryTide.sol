// SPDX-License-Identifier: MIT

/// @title Angry Tide
/// @author Pizza Labs

/*
                                                                                          ===    ==    ====
                                                                                       ======= ===== ==============           
                                                                                     -=================+%@@@@@@@@@@+===  .    
                                                                                    =*@@@@@@+==========@@@@-   *@@@@===      
                                                                                      @@@@@@@@@*%@#==@  @*  =-    =*@@#==-    
            ======                                   -           =====               .  @@@:.+===@%*=+@+     ========#@@===   
          ===*@@@+=====                       =============  =====+++=======             @@@*-=@@@@     =-   -========+@@==   
        ===+@@@@@@@@@+=========     ======  ===*@@@@@@@@@== ==*@@@@@@@@@@@%=== ======                   :===============@@==  
       ==+@@@@@@@@@@@=======+*+==============@@@@@@@@@@@@== ==%@@@@@@@@@@@@@%===%%+======      .        ================-@*== 
     ===@@@@@@@@@@@@@==*@@@@@@@+===@@@@@@#==@@@@@@@@@@@@@=====@@@@@@@ @@@@@@@*==@@@@@@@============     =================*@== 
   ===@@@@@@@@@@@@@@#==*@@@@@@@@===@@@@@@#=@@@@@@@*=======+===@@@@@@   @@@@@@@==+@@@@@@===@@*=======    @++======@========@*= 
 ===#@@@@@@@@ @@@@@@===*@@@@@@@@@==@@@@@@*+@@@@@@*=@@@@@@@@+=*@@@@@@  @@@@@@@+===@@@@@@=#@@@@@@@+==    @@@=+==+@@*=+@@@%==@#==
==+@@@@@@@@@@@@@@@@#===*@@@@@@@@@@=@@@@@@+*@@@@@@+=@@@@@@@@*=%@@@@@@@@@@@@@@%====@@@@@@@@@@@@@=====     =====*@@@=+@@@@@@%@@==
==*@@@@@@@@@@@@@@@@+===*@@@@@@@@@@@@@@@@@=+@@@@@@@=++=*@@@@@=@@@@@@@@@@@@@#=== ==#@@@@@@@@@@===         ===--@@@@@@@@@@@@@@#==
 ====#@@*==#@@@@@@@====#@@@@@@%@@@@@@@@@@==%@@@@@@@@@@@@@@@@=@@@@@@  @@@@@*==  ==+@@@@@@@@==============-    @@# *@@-  #@@@+==
    =======+@@@@@@*====#@@@@@%=@@@@@@@@@@===%@@@@@@@@@@@@@@@@@@@@@@  @@@@@@==- ==@@@@@@@@===================+@@   @@%    @*===
         ===#@@@@@+====%@@@@@*==@@@@@@@@@@@@@@@%#+====*@=========%@@@@@@@@@@====%@@@@@@@@@#+====================. +@@* *@=====
           ======*== ==%@@@@@*=#@@@@@#*+=======#@@@@@=+*=@@@@@@@@*==@@@@@=%@@@+=@@@@@@@@+=================================-==-
                ===  ==@@@@@@*=#@==*#%@@@@@@@@@*@@@@@++==@@@@@@@@@@+=@@@=*#==+@@@@@@@@@@%%%@@@@@@===========================% 
                     ==========@@#=@@@@@@@@@@@@=@@@@@*==#@@@@@@@@@@@==@=#@@@@@===*@@@        @@+====================*=====*@  
                                @@=@@@@@@@@@#*+=@@@@@#==@@@@@@ @@@@@+==#@@@@@@@@@%==*@@     @@@+=====+#@@@@=======#@@===*@    
                                @@====+@@@@@=+@=%@@@@%=+@@@@@  @@@@@==*@@@@@@@@@@@=+@@       @@@@@@@@@@  @@====+@@@@@@@@      
                                @@@@@+=@@@@@=+@==@@@@@=*@@@@@ @@@@@#=*@@@@@@%==+%=*@@                    @@@@@@@@@            
                                    @*=@@@@@==@+=@@@@@=@@@@@@@@@@@+=*@@@@@@@@@==*#@@                                          
                                    @@=%@@@@==@@=@@@@@=@@@@@@@@*===*@@@@@+==*==@@@@                                     
                                    @@=#@@@@+=@@======**+====+*%@=+@@@@@@@@@#==@@@                                            
                                    @@+=+=====@@@@@@@@@@@@@@@@@@@%===#@@@@@@+=@@@                                             
                                     @%%@@@@@@@@                 @@@@#==+%@+=@@@                                                       
*/

pragma solidity ^0.8.19;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/Address.sol";

contract AngryTide is ERC721A, Ownable, ERC2981 {
    using Address for address;
    using MerkleProof for bytes32[];
    bytes32 public merkleRoot;
    uint256 public MaxperWallet = 5;
    uint256 public MaxperWalletWl = 1;
    uint256 public maxSupply = 6888;
    uint256 public wlSupply = 550;
    uint256 public whiteListRate = 0.00 ether;
    uint256 public mintRate = 0.015 ether;
    string public baseURI = "";
    string public baseHiddenUri = "";
    bool public revealed = false;
    bool public paused = true;
    bool public preSale = true;

    mapping(address => uint256) public whiteListUsedAddresses;
    mapping(address => uint256) public usedAddresses;

    // Custom error
    error PublicSaleNotLive();
    error WhitelistNotLive();
    error ExceededLimit();
    error NotEnoughTokensLeft();
    error WrongEther();
    error InvalidMerkle();
    error ContractIsPaused();

    /// @notice Initializes the contract with the initial owner
    /// @param initialOwner The address of the initial owner of the contract
    constructor(address initialOwner)
        ERC721A("Angry Tide", "ANGRY")
        Ownable(initialOwner)
    {
        _setDefaultRoyalty(_msgSender(), 400);
    }

    /// @notice Public mint
    /// @param quantity The number of tokens to mint
    function mint(uint256 quantity) external payable {
        // check if public sale is live
        if (preSale != false) revert PublicSaleNotLive();

        // check if the contract is paused
        if (paused != false) revert ContractIsPaused();

        // check if enough token balance
        if (totalSupply() + quantity > maxSupply) {
            revert NotEnoughTokensLeft();
        }

        // check for the value user pass is equal to the quantity and the mintRate
        if (mintRate * quantity != msg.value) {
            revert WrongEther();
        }

        // check for user mint limit
        if (quantity + usedAddresses[msg.sender] > MaxperWallet) {
            revert ExceededLimit();
        }

        usedAddresses[msg.sender] += quantity;
        _mint(msg.sender, quantity);
    }

    /// @notice Presale mint for whitelisted
    /// @param quantity The number of tokens to mint
    /// @param proof The Merkle proof to verify eligibility
    function presalemint(uint256 quantity, bytes32[] calldata proof) external payable {
        // check if presale is live
        if (preSale != true) revert WhitelistNotLive();

        // check if the contract is paused
        if (paused != false) revert ContractIsPaused();

        // check if the user is whitelisted.
        if (!isWhiteListed(msg.sender, proof)) revert InvalidMerkle();

        // check if enough token balance
        if (totalSupply() + quantity > wlSupply) {
            revert NotEnoughTokensLeft();
        }

        // check for the value user pass is equal to the quantity and the mintRate
        if (whiteListRate * quantity != msg.value) {
            revert WrongEther();
        }

        // cehck if user exceeded mint limit
        if (whiteListUsedAddresses[msg.sender] + quantity > MaxperWalletWl) {
            revert ExceededLimit();
        }

        _mint(msg.sender, quantity);
        // storing the number of minted items
        whiteListUsedAddresses[msg.sender] += quantity;
    }

    /// @notice a function that check for user address and verify its proof
    function isWhiteListed(address _account, bytes32[] calldata _proof)
        internal
        view
        returns (bool)
    {
        return _verify(leaf(_account), _proof);
    }

    function leaf(address _account) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(_account));
    }

    function _verify(bytes32 _leaf, bytes32[] memory _proof)
        internal
        view
        returns (bool)
    {
        return MerkleProof.verify(_proof, merkleRoot, _leaf);
    }

    /// @notice Airdrops a specified quantity of tokens to an address
    /// @dev Requires owner
    /// @param quantity The number of tokens to airdrop
    /// @param destination The address to receive the airdrop
    function airdrop(uint256 quantity, address destination) external onlyOwner {
        if (totalSupply() + quantity > maxSupply) {
            revert NotEnoughTokensLeft();
        }

        _mint(destination, quantity);
    }

    /// @notice Overrides the start token ID to be  1
    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }

    /// @notice This is an internal function that returns base URI
    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    /// @notice Returns the URI for a specific token ID
    /// @param tokenId The ID of the token to get the URI for
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require( _exists(tokenId), "URI query for nonexistent token");
    
        if(revealed == false) { return baseHiddenUri; }

        string memory currentBaseURI = _baseURI();
        return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, _toString(tokenId), ".json"))
        : "";
    }

    /// @notice Sets the Merkle root for verifying whitelisted addresses
    /// @dev Requires owner
    /// @param _merkleRoot The new Merkle root
    function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        merkleRoot = _merkleRoot;
    }

    /// @notice Sets the max per wallet
    /// @dev Requires owner
    /// @param _limit Number to set as max per wallet
    function setMaxPerWallet(uint256 _limit) external onlyOwner {
        MaxperWallet = _limit;
    }

    /// @notice Sets the max per wallet (only for presale)
    /// @dev Requires owner
    /// @param _limit Number to set as max per wallet
    function setMaxPerWalletWl(uint256 _limit) external onlyOwner {
        MaxperWalletWl = _limit;
    }

    /// @notice Cut the supply
    /// @dev Requires owner
    /// @param _newsupply Max number of tokens
    function setMaxsupply(uint256 _newsupply) external onlyOwner {
        maxSupply = _newsupply;
    }
    /// @notice Sets the max supply (only for presale)
    /// @dev Requires owner
    /// @param _newsupply Max number of tokens
    function setWlsupply(uint256 _newsupply) external onlyOwner {
        wlSupply = _newsupply;
    }

    /// @notice Sets the selling price
    /// @dev Requires owner
    /// @param _newRate Amount in Wei
    function setMintRate(uint256 _newRate) external onlyOwner {
        mintRate = _newRate;
    }

    /// @notice Sets the selling price (only for presale)
    /// @dev Requires owner
    /// @param _newRate Amount in Wei
    function setWhiteListRate(uint256 _newRate) external onlyOwner {
        whiteListRate = _newRate;
    }

    /// @notice Reveals the NFTs
    /// @dev Requires owner
    /// @param _state (booleans true or false)
    function setRevealed(bool _state) external onlyOwner {
        revealed = _state;
    }

    /// @notice Sets the base URI
    /// @dev Requires owner
    /// @param _newBaseURI The base URI for revealed NFTs
    function setBaseURI(string memory _newBaseURI) external onlyOwner {
        baseURI = _newBaseURI;
    }

    /// @notice Sets the hidden URI
    /// @dev Requires owner
    /// @param _newBaseHiddenUri The base URI for unrevealed NFTs
    function setBaseHiddenUri(string memory _newBaseHiddenUri) external onlyOwner {
        baseHiddenUri = _newBaseHiddenUri;
    }

    /// @notice Pauses the contract, preventing further minting
    /// @dev Requires owner
    /// @param _state (booleans true or false)
    function pause(bool _state) external onlyOwner {
        paused = _state;
    }
    /// @notice Activate or deactivate presale
    /// @dev Requires owner
    /// @param _state (booleans true or false)
    function togglepreSale(bool _state) external onlyOwner {
        preSale = _state;
    }

    /// @notice Withdraw funds from contract
    /// @dev Requires owner
    /// @param _amount Amount in Ether
    function withdraw(uint256 _amount) external onlyOwner {
        uint256 balance = address(this).balance;
        require(_amount <= balance, 'not enough funds');
        payable(msg.sender).transfer(_amount);
    }

    /// @notice Withdraw all funds from contract
    /// @dev Requires owner
    function withdrawAll() external onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    /// @notice Function to change the royalty info
    /// @dev Requires owner
    /// @param numerator Is the new royalty percentage, in basis points (out of 10,000)
    function setDefaultRoyalty( address payable receiver, uint96 numerator) external onlyOwner {
        _setDefaultRoyalty(receiver, numerator);
    }

    /// @notice Overrides supportsInterface function
    function supportsInterface(bytes4 interfaceId) public view override(ERC721A, ERC2981) returns (bool) {
        return ERC721A.supportsInterface(interfaceId) || ERC2981.supportsInterface(interfaceId);
    }
}