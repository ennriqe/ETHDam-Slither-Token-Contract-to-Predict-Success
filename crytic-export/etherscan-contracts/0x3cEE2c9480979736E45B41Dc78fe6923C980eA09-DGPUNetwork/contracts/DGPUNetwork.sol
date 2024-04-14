// SPDX-License-Identifier: unlicense
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract DGPUNetwork is ERC721Enumerable, Ownable{
    struct NftInfo {
        uint256 tokenId;
        bool nodeType;
        uint256 claimableReward;
        uint256 claimedReward;
    }
    struct nodeClaimInfo {
        uint256 lastClaimTime;
        uint256 claimedReward;
    }
    mapping(uint256 => nodeClaimInfo) public nodeRewardsInfo;

    address public jpuAddress;
    uint256 public nonGpuRPS;
    uint256 public gpuRps;
    uint256 public maxSupply = 20000;
    uint256 public withdrawPenalty;

    uint256 public nonGpuMintPrice;
    uint256 public gpuMintPrice;
    uint256 public nftId;
    string private gpuUri = "https://nft.dgpu.network/1";
    string private nonGpuUri = "https://nft.dgpu.network/2";

    mapping(uint256 => bool) public gpuNode;
    mapping(uint256 => string) private _uri;

    error maxSupplyMinted();
    error unauthorizedCall();
    error ZeroApyNotAllowed();

    constructor() ERC721("DGPU Nodes", "DGPUN") Ownable(msg.sender) {
        nftId = 1;
        gpuMintPrice = 40000 * 10 ** 18;
        nonGpuMintPrice = 50000 * 10 ** 18;
        withdrawPenalty = 4;
        gpuRps = 7610350076103500;
        nonGpuRPS = 6341958396752920;
    }

    function mint(bool _gpu, uint256 _amount) external {
        if(totalSupply() + 1 > maxSupply) {
            revert maxSupplyMinted();
        }
        if(_gpu) {
            IERC20(jpuAddress).transferFrom(msg.sender, address(this), gpuMintPrice);
            _mint(msg.sender, nftId);
            _uri[nftId] = gpuUri;
            gpuNode[nftId] = true;
            nodeRewardsInfo[nftId].lastClaimTime = block.timestamp;
            nftId++;
        } else {
            uint256 totalCost = nonGpuMintPrice * _amount;
            IERC20(jpuAddress).transferFrom(msg.sender, address(this), totalCost);
            for(uint256 j; j < _amount;j++) {
                _mint(msg.sender, nftId);
                _uri[nftId] = nonGpuUri;
                gpuNode[nftId] = false;
                nodeRewardsInfo[nftId].lastClaimTime = block.timestamp;
                nftId++;
            }
        }
        
    }

    function withdraw(uint256 _id) external {
        require(ownerOf(_id) == msg.sender, "NodeX error: Caller is not owner");
        uint256 mintCost;
        if(gpuNode[_id]) {
            mintCost = gpuMintPrice;
        } else {
            mintCost = nonGpuMintPrice;
        }
        uint256 withdrawFee = (mintCost * withdrawPenalty) / 100;
        _burn(_id);
        IERC20(jpuAddress).transfer(owner(), withdrawFee);
        IERC20(jpuAddress).transfer(msg.sender, mintCost - withdrawFee);
    }

    function claimRewards(uint56[] memory _ids) external {
        uint256 availableClaim;
        for(uint256 k; k < _ids.length; k++) {
            if(msg.sender != ownerOf(_ids[k])) {
                revert unauthorizedCall();
            }
            availableClaim += claimableRewards(_ids[k]);
            nodeRewardsInfo[_ids[k]].claimedReward += claimableRewards(_ids[k]);
            nodeRewardsInfo[_ids[k]].lastClaimTime = block.timestamp;
        }
        IERC20(jpuAddress).transfer(msg.sender, availableClaim);
    }

    function claimableRewards(uint256 _nftId) public view returns(uint256) {
        _requireOwned(_nftId);
        uint256 duration = block.timestamp - nodeRewardsInfo[_nftId].lastClaimTime;
        uint256 rewardRate;
        if(gpuNode[_nftId]) {
            rewardRate = gpuRps;
        } else {
            rewardRate = nonGpuRPS;
        }
        return duration * rewardRate;
    }

    function tokenURI(uint256 _tokenId) public view override returns(string memory) {
        _requireOwned(_tokenId);
        return _uri[_tokenId];
    }

    function setJpuAddress(address _add) external onlyOwner {
        jpuAddress = _add;
    }

    function setNonGpuMintPrice(uint256 _newPrice) external onlyOwner {
        nonGpuMintPrice = _newPrice;
    }

    function setGpuMintPrice(uint256 _newPrice) external onlyOwner {
        gpuMintPrice = _newPrice;
    }
    function setGpuRps(uint256 _newRps) external onlyOwner {
        if(_newRps == 0) {
            revert ZeroApyNotAllowed();
        }
        gpuRps = _newRps;
    }

    function setNonGpuRps(uint256 _newRps) external onlyOwner {
        if(_newRps == 0) {
            revert ZeroApyNotAllowed();
        }
        nonGpuRPS = _newRps;
    }

    function getUserNftsInfo(address _account)
        external
        view
        returns (NftInfo[] memory)
    {
        require(_account != address(0), "NodeX error: zero address");
        uint256 userBalance = balanceOf(_account);
        NftInfo[] memory userNftsInfo = new NftInfo[](userBalance);

        if (userBalance > 0) {
            for (uint256 i = 0; i < userBalance; i++) {
                uint256 nftIds = tokenOfOwnerByIndex(_account, i);
                userNftsInfo[i] = NftInfo(
                    nftIds,
                    gpuNode[nftIds],
                    claimableRewards(nftIds),
                    nodeRewardsInfo[nftIds].claimedReward
                );
            }
        }

        return userNftsInfo;
    }
}