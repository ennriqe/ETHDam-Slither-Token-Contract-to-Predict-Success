// SPDX-License-Identifier: GPL-3.0
// solhint-disable-next-line
pragma solidity 0.8.20;

import "./ERC721A.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./IEscrow.sol";

contract ForgeNFT is ERC721A, Ownable, ReentrancyGuard {
    using Strings for uint256;

    string baseURI;

    /// @notice Max supply of Forge Token to be minted
    uint256 public constant MAX_SUPPLY = 5555;

    /// @notice Max supply of Forge Token to be minted using ERC-20
    uint256 public nonEthMaxSupply = 500;

    /// @notice Reserve amount for the Forge Token from escrow contract
    uint256 public reserveAmount = 506;

    /// @notice Public supply of token minted
    uint256 public publicSupply = MAX_SUPPLY - reserveAmount -  nonEthMaxSupply;

    /// @notice current supply of token minted using ERC-20
    uint256 public nonEthCurrentSupply = 0;

    /// @notice Max minting limit using ERC20 per wallet
    uint256 public nonEthMintLimit = 2;

    /// @notice Mint price for each tier
    uint256 public publicMintPrice = 0.065 ether;

    /// @notice Maximum mint per tier per wallet
    uint256[] public tierMaxSupply = [reserveAmount, publicSupply, nonEthMaxSupply];

    /// @notice Signer address for encrypted signatures
    address public secret;

    /// @notice Escrow contract address
    address public escrowAddress;

    /// @notice Public minting status
    bool public isPublicOpen = false;

    /// @notice Mapping for minted tokens per tier
    mapping(uint256 => uint256) public mintedPerTier;

    /// @notice Mapping for ERC20 token price
    mapping(address => uint256) public erc20Price;

    /// @notice Mapping for ERC20 token mint limit
    mapping(address => uint256) public erc20Limit;

    /// @notice Track ERC20 minted for each token
    mapping(address => uint256) public erc20Minted;

    /// @notice Track ETH minted for each tier per wallet
    mapping(address => mapping(uint256 => uint256)) public ethMintedPerTier;

    /// @notice Track ERC20 minted for each token per wallet
    mapping(address => mapping(address => uint256)) public nonEthMintedPerToken;

    /// @notice Check if the wallet claimed the free mint/escrow
    mapping(address => bool) public reserveClaimed;

    /// @notice Mapping for used signatures
    mapping(bytes => bool) public usedSignatures;

    struct PurchaseInfo {
        uint256 quantity;
        address paymentToken;
        uint256 priceOrTier;
        uint256 maxMintPerTier;
    }

    event Purchased(
        address operator,
        address user,
        uint256 currentSupply,
        PurchaseInfo[] purchases,
        uint256 timestamp
    );

    event Refunded(address user, uint256 tokenId);

    event Erc20TokenWhitelisted(address[] tokenAddresses, uint256[] prices, uint256[] limits);

    event MintLimitChanged(
        uint256 newReserveAmount,
        uint256 newPublicSupply,
        uint256 newNonEthMaxSupply,
        address operator
    );

    event Received(address, uint256);

    event MintPriceChanged(uint256);

    event EscrowAddresSet(address);

    /// @param _secret Signer address
    /// @param _escrowAddress Escrow contract address
    /// @dev Create ERC721A token: The Forge - FORGE
    constructor(address _secret, address _escrowAddress) ERC721A("The Forge", "FORGE") {
        secret = _secret;
        escrowAddress = _escrowAddress;        
    }

    receive() external payable {
        emit Received(msg.sender, msg.value);
    }

    /// @notice Check if the wallet is valid
    /// @dev Revert transaction if zero address
    modifier noZeroAddress(address _address) {
        require(_address != address(0), "Cannot send to zero address");
        _;
    }

    /// @notice Mint function is want to be called from etherscan
    /// @param quantity Amount of tokens to be minted
    /// @param paymentToken Address of the payment token
    /// @dev This function only works on public minting
    function mint(uint256 quantity,address paymentToken) external payable{      
        require(isPublicOpen, "mint: Public minting is not open"); 
       
        require(
            quantity > 0,
            "mint: Quantity must be more than zero"
        );
      
        if (paymentToken != address(0)){ 
            require(
                mintedPerTier[2] + quantity <= tierMaxSupply[2],
                "mint: Tier supply limit exceed"
            );   
            require(
                nonEthMintedPerToken[msg.sender][paymentToken] + quantity <= nonEthMintLimit,
                "mint: Exceed mint limit"
            );

            mintedPerTier[2] += quantity; 
            nonEthMintedPerToken[msg.sender][paymentToken] += quantity;             

            uint256 tokenPrice = erc20Price[paymentToken];

            require(
                tokenPrice > 0,
                "mint: Token not whitelisted"
            );      
          
            require(
                IERC20(paymentToken).transferFrom(
                    msg.sender,
                    address(this),
                   tokenPrice
                ),
                "mint: Token transfer failed"
            );            
        } else {                   
            require(
                mintedPerTier[1] + quantity <= tierMaxSupply[1],
                "mint: Tier supply limit exceed"
            );

            mintedPerTier[1] += quantity; 

            require(msg.value == publicMintPrice * quantity, "mint: Invalid ETH amount");
        }

        uint256 currentSupply = _totalMinted();

        require(
            currentSupply + quantity <= MAX_SUPPLY,
            "mint: Supply limit"
        );

        _safeMint(msg.sender, quantity);

        emit Purchased(
            msg.sender,
            msg.sender,
            currentSupply,
            new PurchaseInfo[](0),
            block.timestamp
        );
    }

    /// @notice Purchase an Forge NFT using whitelisted ECR20 tokens or ETH
    /// @param to Address to send the tokens
    /// @param totalQuantity Total amount of tokens to be minted
    /// @param purchases Array of PurchaseInfo struct
    /// @param signature Encrypted signature to verify the minting
    function purchase(
        address to,
        uint256 totalQuantity,
        PurchaseInfo[] memory purchases,
        bytes memory signature
    ) external payable {
        require(
            _verifyHashSignature(
                keccak256(abi.encode(to, purchases, msg.value)),
                signature
            ),
            "purchase: Signature is invalid"
        );

        uint256 currentSupply = _totalMinted();

        require(
            totalQuantity + currentSupply <= MAX_SUPPLY,
            "purchase: Supply limit"
        );        

        for (uint256 i = 0; i < purchases.length; i++) {
            PurchaseInfo memory purchaseInfo = purchases[i];

            _validateMintingParameters(
                to,
                purchaseInfo.paymentToken,
                purchaseInfo.priceOrTier,
                purchaseInfo.quantity,
                purchaseInfo.maxMintPerTier
            );
        }           

        _safeMint(to, totalQuantity);

        emit Purchased(
            msg.sender,
            to,
            currentSupply,
            purchases,
            block.timestamp
        );
    }

    /// INTERNAL FUNCTIONS

    /// @notice Check if the wallet has claimed the escrow reserve and claim it if not
    /// @param to Address to check
    function _checkEscrow(address to) internal {
        require(
            escrowAddress != address(0),
            "_checkEscrow: Escrow address not set"
        );
        require(
            !reserveClaimed[to],
            "_checkEscrow: Reserve already claimed"
        );

        reserveClaimed[to] = true;

        IEscrow escrow = IEscrow(escrowAddress);
        IEscrow.NftReserve memory nftReserve = escrow.nftReserveAmount(to);

        if (nftReserve.publicReserved > 0 || nftReserve.coFounderReserved > 0) {
            escrow.claimFor(to);           
        }
    }

    function _validateMintingParameters(
        address to,
        address tokenAddress,
        uint256 priceOrTier,
        uint256 quantity,
        uint256 maxMintPerTier
    ) internal {
        if(priceOrTier == 0){
          _checkEscrow(to);
        }

        if (tokenAddress == address(0)) {
            if(priceOrTier != 2){
                require(
                    ethMintedPerTier[to][priceOrTier] + quantity <= maxMintPerTier,
                    "_validateMintingParameters: Exceed tier mint limit"
                );

                ethMintedPerTier[to][priceOrTier] += quantity;
            }

            require(
                mintedPerTier[priceOrTier] + quantity <= tierMaxSupply[priceOrTier],
                "_validateMintingParameters: Tier supply limit exceed"
            );

            mintedPerTier[priceOrTier] += quantity;          
        } else {           
            // require that to has at least 1 NFT already minted
            require(
                balanceOf(to) > 0 || msg.value > 0,
                "_validateMintingParameters: User has no NFT"
            );          
            require(
               nonEthMintedPerToken[to][tokenAddress] + quantity <= nonEthMintLimit,
                "_validateMintingParameters: Exceed mint limit"
            );            
            require(
                erc20Minted[tokenAddress] + quantity <= erc20Limit[tokenAddress],
                "_validateMintingParameters: Exceed ERC-20 mint limit"
            );
            require(
                mintedPerTier[2] + quantity <= tierMaxSupply[2],
                "_validateMintingParameters: Tier supply limit exceed"
            );

            nonEthMintedPerToken[to][tokenAddress] += quantity;
            erc20Minted[tokenAddress] += quantity;               
            mintedPerTier[2] += quantity;               
           
            require(
                IERC20(tokenAddress).transferFrom(
                    msg.sender,
                    address(this),
                    priceOrTier
                ),
                "_validateMintingParameters: Token transfer failed"
            );                   
        }
    }

    /// @notice Verify that message is signed by secret wallet
    function _verifyHashSignature(
        bytes32 freshHash,
        bytes memory signature
    ) internal view returns (bool) {
        bytes32 hash = keccak256(
            abi.encodePacked("\x19Ethereum Signed Message:\n32", freshHash)
        );

        bytes32 r;
        bytes32 s;
        uint8 v;

        if (signature.length != 65) {
            return false;
        }
        assembly {
            r := mload(add(signature, 32))
            s := mload(add(signature, 64))
            v := byte(0, mload(add(signature, 96)))
        }

        if (v < 27) {
            v += 27;
        }

        address signer = address(0);
        if (v == 27 || v == 28) {
            // solium-disable-next-line arg-overflow
            signer = ecrecover(hash, v, r, s);
        }
        return secret == signer;
    }

    /// OWNABLE FUNCTIONS

    /// @notice Set the mint limit for each tier
    /// @param newReserveAmount New reserve amount
    /// @param newPublicSupply New public supply
    /// @param newNonEthMaxSupply New non-ETH max supply
    /// @dev Safety check to prevent supply limit exceed
    function setMintLimit(
        uint256 newReserveAmount,
        uint256 newPublicSupply,
        uint256 newNonEthMaxSupply
    ) external onlyOwner {
        require(
            newReserveAmount + newPublicSupply + newNonEthMaxSupply == MAX_SUPPLY,
            "setMintLimit: Invalid supply"
        );

        uint256 currentReserveMinted = mintedPerTier[0];
        uint256 currentPublicMinted = mintedPerTier[1];
        uint256 currentNonEthMinted = mintedPerTier[2];

        require(
            newReserveAmount >= currentReserveMinted,
            "setMintLimit: New reserve amount is less than current minted"
        );
        require(
            newPublicSupply >= currentPublicMinted,
            "setMintLimit: New public supply is less than current minted"
        );
        require(
            newNonEthMaxSupply >= currentNonEthMinted,
            "setMintLimit: New non-ETH max supply is less than current minted"
        );

        reserveAmount = newReserveAmount;
        publicSupply = newPublicSupply;
        nonEthMaxSupply = newNonEthMaxSupply;

        emit MintLimitChanged(
            newReserveAmount,
            newPublicSupply,
            newNonEthMaxSupply,
            msg.sender
        );
    }

    /// @notice Set ERC20 token price and mint limit
    /// @param tokenAddresses Addresses of the tokens to be set
    /// @param prices Prices of the tokens to be set
    /// @param limits Limits of the tokens to be set
    /// @dev Can only be called by the contract owner
    function setErc20TokenWhitelist(
        address[] memory tokenAddresses,
        uint256[] memory prices,
        uint256[] memory limits
    ) external onlyOwner {
        require(
            tokenAddresses.length == prices.length &&
                tokenAddresses.length == limits.length,
            "setErc20TokenWhitelist: Invalid input"
        );

        for (uint256 i = 0; i < tokenAddresses.length; i++) {
            erc20Price[tokenAddresses[i]] = prices[i];
            erc20Limit[tokenAddresses[i]] = limits[i];
        }

        emit Erc20TokenWhitelisted(tokenAddresses, prices, limits);
    }

    /// @notice Set the mint price for public minting
    /// @param price New mint price
    /// @dev Can only be called by the contract owner
    function setPublicMintPrice(uint256 price) external onlyOwner {
        publicMintPrice = price;

        emit MintPriceChanged(price);
    }

    /// @notice Set the escrow contract address
    /// @param escrowAddress Address of the escrow contract
    /// @dev Can only be called by the contract owner
    function setEscrowAddress(address escrowAddress) external onlyOwner {
        require(
            escrowAddress != address(0),
            "setEscrowAddress: Zero address"
        );

        escrowAddress = escrowAddress;

        emit EscrowAddresSet(escrowAddress);
    }

    /// @notice Change the Base URI
    /// @param newURI new URI to be set
    /// @dev Can only be called by the contract owner
    function setBaseURI(string memory newURI) external onlyOwner {
        baseURI = newURI;
    }

    /// @notice Change the signer address
    /// @param secretAddress new signer for encrypted signatures
    /// @dev Can only be called by the contract owner
    function setSecret(
        address secretAddress
    ) external onlyOwner noZeroAddress(secretAddress) {
        secret = secretAddress;
    }

    /// @notice Send ETH to specific address
    /// @param to Address to send the funds
    /// @param amount ETH amount to be sent
    /// @dev Can only be called by the contract owner
    function withdrawETH(
        address to,
        uint256 amount
    ) public nonReentrant onlyOwner noZeroAddress(to) {
        require(amount <= address(this).balance, "Insufficient funds");

        (bool success, ) = to.call{value: amount}("");

        require(success, "withdrawETH: ETH transfer failed");
    }

    /// @notice Send ERC20 tokens to specific address
    /// @param to Address to send the funds
    /// @param tokenAddresses Addresses of the tokens to be sent
    /// @dev Can only be called by the contract owner
    function withdrawERC20(
        address to,
        address[] memory tokenAddresses
    ) public nonReentrant onlyOwner noZeroAddress(to) {
        for (uint256 i = 0; i < tokenAddresses.length; i++) {
            IERC20 token = IERC20(tokenAddresses[i]);
            uint256 balance = token.balanceOf(address(this));

            require(balance > 0, "withdrawERC20: Insufficient funds");

            require(
                token.transfer(to, balance),
                "withdrawERC20: Token transfer failed"
            );             
        }
    }

    function setIsPublicOpen(bool status) external onlyOwner {
        isPublicOpen = status;
    }

    /// VIEW FUNCTIONS

    /// @notice Return total minted amount
    function minted() external view returns (uint256) {
        return _totalMinted();
    }

    /// @notice Return Base URI
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    /// @notice Inherit from ERC721, return token URI, revert is tokenId doesn't exist
    function tokenURI(
        uint256 tokenId
    ) public view virtual override returns (string memory) {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        return string(abi.encodePacked(baseURI, tokenId.toString()));
    }

    /// @notice Inherit from ERC721, checks if a token exists
    function exists(uint256 tokenId) external view returns (bool) {
        return _exists(tokenId);
    }
}
