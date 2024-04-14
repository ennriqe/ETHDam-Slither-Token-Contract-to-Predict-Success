// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20BurnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "./AnrytonStorage.sol";

contract Anryton is UUPSUpgradeable,ERC20Upgradeable, ERC20BurnableUpgradeable, OwnableUpgradeable,AnrytonStorage  {
    


    /** track wallet and supply assigned to a particular supply */
    mapping(string => address) private assignedWalletToSale;
    mapping(string => mapping(address => uint256)) private mintedWalletSupply;


    event MintedWalletSuupply(
        string indexed sale,
        uint256 indexed supply,
        address indexed walletAddress
    );

    /**
     * @dev Error indicating that the given amount is zero
     */
    error inputValueZero();
    error TotalSupplyLimitExceeded();

    function initialize(
        string memory _tokenName,
        string memory _tokenSymbol
    ) external initializer {
        __Ownable_init(msg.sender);
        __UUPSUpgradeable_init();
        _latestSale = "FRIEND_FAMILY"; 
        mintingCounter = 0;
        __ERC20_init(_tokenName, _tokenSymbol);
        __ERC20Burnable_init();
        _setCommissions();
    }

    function _setCommissions() private {
        _calcSaleSupply(1, "FRIEND_FAMILY", 0x40F073D687d1F767a2D01cAFA2d2Bdff22fdD3Bd, 12000000 ether);
        _calcSaleSupply(2, "PRIVATE_SALE", 0xca26FC94876777c578D08A1f39de6774b91c67E4, 24000000 ether);
        _calcSaleSupply(3, "PUBLIC_SALE", 0x5C8bD761c4926327CF65B1027FD4CaE4d1ffDD66, 24000000 ether);
        _calcSaleSupply(4, "TEAM", 0xC9E61E82ecD2B84C29409Cb7E5e6255ebAf21151, 40000000 ether);
        _calcSaleSupply(5, "RESERVES", 0x5cA3dc4a9D00D96f2cfe1c61eDDbE532498dfa4A, 100000000 ether);
        _calcSaleSupply(
            6,
            "STORAGE_MINTING_ALLOCATION",
            0xd88A39948B3A62a302c9c6Bb7932ca01c7bD3E05,
            40000000 ether
        );
        _calcSaleSupply(7, "GRANTS_REWARD", 0xF59583ae201583311b288DFe5Dc60158fB1084d4, 80000000 ether);
        _calcSaleSupply(8, "MARKETTING", 0x3f65C00252f5AF049eccFCeDfD024E5F8EeE670f, 40000000 ether);
        _calcSaleSupply(9, "ADVISORS", 0x1e7Bcd3c058aD518Ed38cDA9EeF149dd310a564A, 12000000 ether);
        _calcSaleSupply(
            10,
            "LIQUIDITY_EXCHANGE_LISTING",
            0xC8fc19c358045717Eaa5D6E13824f3969e949826,
            20000000 ether
        );
        _calcSaleSupply(11, "STAKING", 0x975a33A6c0BF5c242D5148d19E7a5e6dc28A1BB0, 8000000 ether);

        /** mint once every partician is done
         * First sale will be get minted "FRIEND_FAMILY"
         */
        mint();
    }

    /***
     * @function _calcSaleSupply
     * @dev defining sales in a contract
     */
    function _calcSaleSupply(
        uint8 serial,
        string memory _name,
        address _walletAddress,
        uint160 _supply
    ) private {
        mintedSale[serial].name = _name;
        mintedSale[serial].supply = _supply;
        mintedSale[serial].walletAddress = _walletAddress;
    }

    /***
     * @function mintTokens
     * @dev mint token on a owner address
     * @notice onlyOwner can access this function
     */
    function mint() public onlyOwner {
        uint8 saleCount = ++mintingCounter;
        MintingSale storage mintingSale = mintedSale[saleCount];
        /** Validate amount and address should be greater than zero */
        if (mintingSale.supply <= 0) {
            revert inputValueZero();
        }

        if (
            totalSupply() == MAX_TOTAL_SUPPLY ||
            totalSupply() + mintingSale.supply > MAX_TOTAL_SUPPLY
        ) {
            revert TotalSupplyLimitExceeded();
        }
        /** Mint and set default sale supply */
        _mint(mintingSale.walletAddress, mintingSale.supply);
        _setSaleSupplyWallet(
            mintingSale.name,
            mintingSale.walletAddress,
            mintingSale.supply
        );
    }

    /***
     * @function _defaultSupplyWallet
     * @dev persist user address attaches with sale name
     */
    function _setSaleSupplyWallet(
        string memory _saleName,
        address _walletAddress,
        uint256 _supply
    ) private {
        _latestSale = _saleName;
        assignedWalletToSale[_saleName] = _walletAddress;
        mintedWalletSupply[_saleName][_walletAddress] = _supply;
        emit MintedWalletSuupply(_saleName, _supply, _walletAddress);
    }

    /***
     * @function getPerSaleWalletSupply
     * @dev return minted supply on a assgined wallet to a sale.
     */
    function getAssignedWalletAndSupply(
        string memory saleName
    ) public view returns (uint256, address) {
        address walletAddress = assignedWalletToSale[saleName];
        uint256 mintedSupply = mintedWalletSupply[saleName][walletAddress];
        return (mintedSupply, walletAddress);
    }

    /***
     * @function getDefaultSale
     * @dev Get default sale name on other contracts
     */
    function getLatestSale() public view returns (string memory) {
        return _latestSale;
    }

    /***
     * @function getMaxSupply
     * @dev returns maxTotalSupply variable
     */
    function getMaxSupply() public pure returns (uint160) {
        return MAX_TOTAL_SUPPLY;
    }


        /**
     * @dev Authorizes an upgrade of the contract's implementation.
     * @param newImplementation The address of the new implementation contract.
     * @notice Only callable by the owner.
     */
    function _authorizeUpgrade(
        address newImplementation
    ) internal virtual override onlyOwner {
    
    }
}

