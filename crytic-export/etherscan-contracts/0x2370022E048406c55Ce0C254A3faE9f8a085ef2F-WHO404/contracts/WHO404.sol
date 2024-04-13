//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {ERC333} from "./ERC333/ERC333.sol";
import {FullMath} from "./utils/FullMath.sol";

contract WHO404 is ERC333 {
    using Strings for uint256;

    string private constant __NAME = "WHO404";
    string private constant __SYM = "WHO";
    uint256 private constant __MINT_SUPPLY = 1000;
    uint24 private constant __TAX_PERCENT = 80000;
    uint8 private constant __DECIMALS = 18;
    uint8 private constant __RATIO = 100;

    address constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

    constructor(
        address initialOwner_,
        address initialMintRecipient_
    )
        ERC333(
            initialOwner_,
            initialMintRecipient_,
            __MINT_SUPPLY,
            __TAX_PERCENT,
            __NAME,
            __SYM,
            __DECIMALS,
            __RATIO
        )
    {
        baseURI = "https://who404.wtf/assets/";
    }

    function initialize() external payable override onlyOwner {
        address positionManagerAddress = 0xC36442b4a4522E871399CD717aBDD847Ab11FE88;
        address swapRouterAddress = 0xE592427A0AEce92De3Edee1F18E0157C05861564;

        if (msg.value > 0) {
            depositETH(msg.value);
        }

        uint160 sqrtPriceX96 = (address(this) < WETH)
            ? 1372272028650297984479657984 // 0.0003
            : 4574240095500993129133247561728; // 3333.333333333333

        uint256 quoteTokenAmount = _getWETHAtSqrtPriceX96(sqrtPriceX96);
        // require(quoteTokenAmount > 14e17, "quoteTokenAmount");

        uint256 wethAmount = balanceOfWETH();
        require(wethAmount >= quoteTokenAmount, "weth amount is too low");

        _initialize(
            sqrtPriceX96,
            3000,
            WETH,
            quoteTokenAmount,
            60,
            positionManagerAddress,
            swapRouterAddress
        );
    }

    function balanceOfWETH() internal returns (uint256 amount) {
        // Call balanceOf
        // 0x70a08231: keccak256(balanceOf(address))
        (bool success, bytes memory data) = WETH.staticcall(
            abi.encodeWithSelector(0x70a08231, address(this))
        );
        if (success) {
            // Decode `uint256` from returned data
            amount = abi.decode(data, (uint256));
        }
    }

    function depositETH(uint256 amount) internal returns (bool) {
        // Deposit the eth
        // Call deposit
        // 0xd0e30db0: keccak256(deposit())
        (bool success, ) = WETH.call{value: amount}(
            abi.encodeWithSelector(0xd0e30db0)
        );
        return success;
    }

    function _getWETHAtSqrtPriceX96(
        uint160 sqrtPriceX96
    ) private view returns (uint256 quoteAmount) {
        // Calculate quoteAmount with better precision if it doesn't overflow when multiplied by itself
        uint256 thisAmount = balanceOf[address(this)];
        if (sqrtPriceX96 <= type(uint128).max) {
            uint256 ratioX192 = uint256(sqrtPriceX96) * sqrtPriceX96;
            quoteAmount = address(this) < WETH
                ? FullMath.mulDiv(ratioX192, thisAmount, 1 << 192)
                : FullMath.mulDiv(1 << 192, thisAmount, ratioX192);
               
        } else {
            uint256 ratioX128 = FullMath.mulDiv(
                sqrtPriceX96,
                sqrtPriceX96,
                1 << 64
            );
            quoteAmount = address(this) < WETH
                ? FullMath.mulDiv(ratioX128, thisAmount, 1 << 128)
                : FullMath.mulDiv(1 << 128, thisAmount, ratioX128);
                
        }
    }

    function tokenURI(uint256 id) public view override returns (string memory) {
        uint8 seed = uint8(bytes1(keccak256(abi.encodePacked(id))));
        string memory image;
        string memory color;

        if (seed <= 64) {
            image = "0.png";
            color = "Red";
        } else if (seed <= 128) {
            image = "1.png";
            color = "Blue";
        } else if (seed <= 192) {
            image = "2.png";
            color = "Green";
        } else {
            image = "3.png";
            color = "Purple";
        }

        return
            string(
                abi.encodePacked(
                    '{"name": "WHO404 NFT#',
                    Strings.toString(id),
                    '","description":"A collection of ',
                    Strings.toString(mintSupply),
                    " pots of liquidity that tokenizes decentralized reserve currency idea for the IQ50, #ERC333.",
                    '","external_url":"https://who404.wtf/","image":"',
                    baseURI,
                    image,
                    '","attributes":[{"trait_type":"Color","value":"',
                    color,
                    '"}]}'
                )
            );
    }

    receive() external payable {
        depositETH(msg.value);
    }
}
