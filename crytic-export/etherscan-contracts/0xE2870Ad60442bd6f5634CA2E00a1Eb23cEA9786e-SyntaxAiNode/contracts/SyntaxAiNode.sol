// SPDX-License-Identifier: unlicense
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

contract SyntaxAiNode is Ownable, ERC721Enumerable {
    using SafeERC20 for IERC20;

    struct NftInfo {
        uint256 tokenId;
        uint256 claimedReward;
        uint256 claimableReward;
    }
    struct ClaimData {
        uint256 lastClaimTime;
        uint256 claimedReward;
    }

    IERC20 public token;
    uint256 public mintPrice;
    uint256 public maxSupply;
    uint256 public rewardRate;
    mapping(address => uint256) public userClaimedRewards;
    mapping(uint256 => ClaimData) public claimInfo;
    mapping(address => uint256) public userTokensMinted;

    uint256 public tokenId;
    uint256 public refundFee;
    address public feeCollector;

    constructor() ERC721("Syntax AI Node", "NodeX") Ownable(msg.sender) {
        maxSupply = 777;
        mintPrice = 500 * 10 ** 18;
        tokenId = 1;
        feeCollector = msg.sender;
    }

    function mint(uint256 _amount) external {
        require(_amount != 0, "NodeX error: _amount >  0");
        require(tokenId + _amount <= maxSupply, "NodeX error: Max supply reached");
        uint256 mintingFee = mintPrice * _amount;

        for (uint256 i; i < _amount; ) {
            _mint(msg.sender, tokenId);
            claimInfo[tokenId].lastClaimTime = block.timestamp;
            unchecked {
                tokenId++;
                i++;
            }
        }
        userTokensMinted[msg.sender] += _amount;
        token.safeTransferFrom(msg.sender, address(this), mintingFee);
    }

    function returnNFT(uint256 _tokenId) external {
        require(ownerOf(_tokenId) == msg.sender, "NodeX error: Caller is not owner");
        (uint256 fees, uint256 refundAmount) = calculateRefundFee();
        _burn(_tokenId);
        token.safeTransfer(feeCollector, fees);
        token.safeTransfer(msg.sender, refundAmount);
    }

    function getClaimableRewards(uint256[] memory _tokenIds) external {
        uint256 availableRewards;
        for (uint256 i; i < _tokenIds.length; ) {
            require(ownerOf(_tokenIds[i]) == msg.sender, "NodeX error: Caller is not owner");
            uint256 tokenReward = getRewards(_tokenIds[i]);
            availableRewards += tokenReward;
            claimInfo[_tokenIds[i]].lastClaimTime = block.timestamp;
            claimInfo[_tokenIds[i]].claimedReward += tokenReward;

            unchecked {
                i++;
            }
        }
        userClaimedRewards[msg.sender] += availableRewards;
        token.safeTransfer(msg.sender, availableRewards);
    }

    function setRefundFee(uint256 _fee) external onlyOwner {
        require(_fee <= 10, "NodeX error: _fee cannot be greater than 10%");
        refundFee = _fee;
    }

    function setToken(address _tokenAdd) external onlyOwner {
        require(_tokenAdd != address(0), "NodeX error: Can't be zero address");
        token = IERC20(_tokenAdd);
    }

    function setRewardRate(uint256 _rps) external onlyOwner {
        require(_rps != 0, "NodeX error: Can't be zero");
        rewardRate = _rps;
    }

    function setMintFee(uint256 _fee) external onlyOwner {
        mintPrice = _fee;
    }

    function getRewards(uint256 _tokenId) public view returns (uint256) {
        require(_requireOwned(_tokenId) != address(0), "NodeX error: token doesn't exists");
        uint256 rewardDuration = block.timestamp -
            claimInfo[_tokenId].lastClaimTime;

        return rewardDuration * rewardRate;
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
                uint256 nftId = tokenOfOwnerByIndex(_account, i);
                uint256 claimableReward = getRewards(nftId);
                userNftsInfo[i] = NftInfo(
                    nftId,
                    claimInfo[nftId].claimedReward,
                    claimableReward

                );
            }
        }

        return userNftsInfo;
    }

    function calculateRefundFee() public view returns (uint256, uint256) {
        uint256 fees = (mintPrice * refundFee) / 100;
        return (fees, mintPrice - fees);
    }

    function tokenURI(uint256 id) public view override returns(string memory) {
        _requireOwned(id);
        return "https://nft.syntaxai.app/nft/1";
    } 
}