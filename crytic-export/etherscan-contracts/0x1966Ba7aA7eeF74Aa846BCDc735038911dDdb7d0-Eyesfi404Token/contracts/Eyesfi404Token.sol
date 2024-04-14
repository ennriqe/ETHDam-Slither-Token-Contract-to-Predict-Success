//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import {ERC404} from "./ERC404.sol";

interface IERC20 {
    function transfer(
        address recipient,
        uint256 amount
    ) external returns (bool);

    function balanceOf(address account) external view returns (uint256);
}

contract Eyesfi404Token is ERC404 {

    using ECDSA for bytes32;

    uint256 public burnFee;
    mapping(uint256 => string) public tokenHashs;
    mapping(address => bool) public signerSets;
    mapping(address => uint256) public nonceSets;

    event BurnNFT(address indexed burner, uint256 tokenId, string btcAddress);

    function addSigner(address _signer) public onlyOwner {
        signerSets[_signer] = true;
    }

    function removeSigner(address _signer) public onlyOwner {
        signerSets[_signer] = false;
    }

    function updateBurnFee(uint256 _burnFee) public onlyOwner {
        burnFee = _burnFee;
    }

    function _hash(uint256 _tokenId, address _address) internal view returns (bytes32)
    {
        return keccak256(abi.encode(_tokenId, getChainID(), nonceSets[_address], address(this), _address));
    }

    function _verify(bytes32 shash, bytes memory token) internal view returns (bool)
    {
        return signerSets[_recover(shash, token)] ;
    }

    function _recover(bytes32 shash, bytes memory token) internal pure returns (address)
    {
        return shash.toEthSignedMessageHash().recover(token);
    }

    function initialize(
        string memory _name,
        string memory _symbol,
        uint8 _decimals,
        uint256 _totalNativeSupply,
        uint8 _power,
        uint256 _maxSupply,
        address _vault,
        uint256 _burnFee
    ) external initializer {
        __ERC404initialize_init(_name, _symbol, _decimals, _totalNativeSupply, _power, _maxSupply, _vault);
        burnFee = _burnFee;
    }

    function getChainID() internal view returns (uint256) {
        uint256 id;
        assembly {
            id := chainid()
        }
        return id;
    }   

    function setNameSymbol(
        string memory _name,
        string memory _symbol
    ) public onlyOwner {
        _setNameSymbol(_name, _symbol);
    }

    function mint(uint256 tokenId, bytes memory token) external nonReentrant whenNotPaused {
        uint256 unit = _getUnit();
        require((totalSupply/unit) <= maxCount, "No mint capacity left");
        require(_verify(_hash(tokenId, msg.sender), token), "Invalid signature");
        nonceSets[msg.sender]++;
        
        _mint(msg.sender, tokenId);
        balanceOf[msg.sender] += unit;
        totalSupply += unit;
    }

    function burnNFT(uint256 tokenId, string memory btcAddress) external payable nonReentrant whenNotPaused {
        require(msg.value >= burnFee, "Insufficient burn fee");

        require(bytes(btcAddress).length != 0, "Invalid BTC address");
        require(_ownerOf[tokenId] == msg.sender, "Not owner");

        (bool find, uint256 findIndex) = findTokenIdIndex(msg.sender, tokenId);
        require(find, "not found tokenId in account tokens");

        if (findIndex != _owned[msg.sender].length - 1) {
            uint256 lastTokenId = _owned[msg.sender][_owned[msg.sender].length-1];
            _owned[msg.sender][findIndex] = lastTokenId;
            _ownedIndex[lastTokenId] = findIndex;
        }
        _owned[msg.sender].pop();

        delete _ownedIndex[tokenId];
        delete _ownerOf[tokenId];
        delete getApproved[tokenId];
        delete tokenHashs[tokenId];

        balanceOf[msg.sender] -= _getUnit();
        totalSupply -= _getUnit();

        emit Transfer(msg.sender, address(0), tokenId);
        emit BurnNFT(msg.sender, tokenId, btcAddress);
    }

    function findTokenIdIndex(address account, uint256 tokenId) internal view returns (bool, uint256) {
        uint256[] memory accountTokens = _owned[account];
        for (uint i; i!=accountTokens.length; i++) {
            if (accountTokens[i] == tokenId) {
                return (true, i);
            }
        }
        return (false, 0);
    }

    function getNonce(address _address) public view returns (uint256) {
        return nonceSets[_address];
    }

    function release() external onlyOwner {
        Address.sendValue(payable(owner()), address(this).balance);
    }

    uint256[46] private __gap;
}
