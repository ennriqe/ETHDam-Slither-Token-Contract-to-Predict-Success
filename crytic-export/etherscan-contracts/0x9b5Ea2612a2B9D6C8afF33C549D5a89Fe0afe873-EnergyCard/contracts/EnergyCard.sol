// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Pausable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract EnergyCard is Ownable, ERC721Pausable {
    using Strings for uint256;

    address public devAddress;

    string private _baseUri;

    bytes32 public merkleRoot;

    uint24 public nextId = 1;

    uint24 public devCount = 400;
    uint24 public lotteryCount = 600;

    mapping(bytes32 => bool) public usedProofs;

    constructor(
        address dev,
        string memory _name,
        string memory _symbol
    ) Ownable(_msgSender()) ERC721(_name, _symbol) {
        devAddress = dev;
    }

    /**
     * @dev See {ERC721-_update}.
     */
    function _update(
        address to,
        uint256 tokenId,
        address auth
    ) internal virtual override returns (address) {
        if(to != address(0) && to != devAddress) {
            //receiver only can hold one
            require(balanceOf(to) == 0, "Limit one");
        }

        return super._update(to, tokenId, auth);
    }

    function setPaused(bool isPaused) external onlyOwner {
        if(isPaused) 
            _pause();
        else 
            _unpause();
    }

    function setMerkleRoot(bytes32 root) external onlyOwner {
        merkleRoot = root;
    }

    function setBaseUri(string memory baseUri) external onlyOwner {
        _baseUri = baseUri;
    }

    /**
    @notice Return the token's metadata URI.
     */
    function tokenURI(
        uint256 tokenId
    ) public view override returns (string memory) {
        return string(abi.encodePacked(_baseUri, "/", tokenId.toString()));
    }

    function devMint() external onlyOwner {
        require(devCount > 0, "Minted");
        for(uint24 i = 0; i < devCount; ) {
            _mint(devAddress, nextId ++);
            unchecked {
                i ++;
            }
        }
        devCount = 0;
    }

    function mint(bytes32[] calldata proof) external {
        require(lotteryCount > 0, "Finished");
        require(_verifyProof(proof), "Invalid Merkle proof");
        unchecked {
            lotteryCount --;
        }
        _mint(_msgSender(), nextId ++);
        
    }

    function batchTransfer(address[] calldata toAddrs, uint24[] calldata ids) external {
        require(toAddrs.length == ids.length, "Length not match");
        for(uint24 i = 0; i < toAddrs.length;) {
            transferFrom(_msgSender(), toAddrs[i], ids[i]);
            unchecked {
                i ++;
            }
        }
    }

    function _verifyProof(bytes32[] calldata proof) internal returns (bool) {
        bytes32 leaf = keccak256(abi.encodePacked(_msgSender()));
        require(!usedProofs[leaf], "Used");
        usedProofs[leaf] = true;
        return MerkleProof.verify(proof, merkleRoot, leaf);
    }

}
