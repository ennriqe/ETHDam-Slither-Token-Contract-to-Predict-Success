// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract BlastAirdropToken is ERC20, Ownable {
    uint256 public constant PERIOD1_DISTRIBUTION_AMOUNT = 10_000_000 * 10 ** 18;
    uint256 public constant PERIOD2_DISTRIBUTION_AMOUNT = 1000_000 * 10 ** 18;
    uint256 public currentDistributionTotalSupply;
    uint256 public currentLiquidityPoolTotalSupply;

    address public mintContract;

    uint256 public changeTime = 1752768000;

    constructor() ERC20("Blast Airdrop Token", "Blast") Ownable(msg.sender) {
        _mint(msg.sender, 21_000_000 * 10 ** 18);
    }

    modifier onlyMintingContract() {
        require(msg.sender == mintContract, "FomosToken: only mintContract can mint");
        _;
    }

    function setMintContract(address _mintContract) external onlyOwner {
        require(_mintContract != address(0), "FomosToken: mintContract is the zero address");
        mintContract = _mintContract;
    }

    function totalSupply() public view override returns (uint256) {
        return 21_000_000 * 10 ** 18;
    }

    function mint() external onlyMintingContract returns (uint256 periodAmount) {
        if (block.timestamp < changeTime) {
            currentDistributionTotalSupply += PERIOD1_DISTRIBUTION_AMOUNT;
            _mint(mintContract, PERIOD1_DISTRIBUTION_AMOUNT);
            periodAmount = PERIOD1_DISTRIBUTION_AMOUNT;
        } else {
            currentDistributionTotalSupply += PERIOD2_DISTRIBUTION_AMOUNT;
            _mint(mintContract, PERIOD2_DISTRIBUTION_AMOUNT);
            periodAmount = PERIOD2_DISTRIBUTION_AMOUNT;
        }
    }

    function liquidityPoolMint(uint256 amount) external onlyMintingContract returns (bool) {
        require(amount > 0, "FomosToken: amount must be greater than zero");
        currentLiquidityPoolTotalSupply += amount;
        _mint(mintContract, amount);
        return true;
    }

    function burn(uint256 amount) external {
        require(amount > 0, "FomosToken: amount must be greater than zero");
        _burn(msg.sender, amount);
    }
}
