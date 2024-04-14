/**

Website:  https://trumpdog.org
Twitter: https://twitter.com/originaltrump_
Telegram: https://t.me/original_trump

*/

// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.18;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
}

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

contract Ownable is Context {
    address private _owner;
    address private _previousOwner;
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    constructor() {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }
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

    function factory() external pure returns (address);

    function WETH() external pure returns (address);
}

contract PUG is Context, IERC20, Ownable {
    uint256 private constant _totalSupply = 100_000_000e18;
    uint256 private constant _onePercent = 1_000_000e18;
    uint256 private _minTokenSwapAmount = 689e18;
    uint256 private _maxSwapTokenAmount = _onePercent;
    uint8 private constant _decimals = 18;

    IUniswapV2Router02 immutable uniswapV2Router;
    address private uniswapPair;
    address immutable WETH;
    address payable _trumpAddr;

    uint256 private _taxOnBuy;
    uint256 private _taxOnSell;
    uint256 private _taxForLP;

    uint8 private launch;
    uint8 private _isInSwap;

    uint256 private _startBlock;
    uint256 private _maxTrxTokens = _onePercent * 2;
    uint256 private _maxWalletHolding = _onePercent * 2;

    string private constant _name = "Original Trump";
    string private constant _symbol = "PUG";

    mapping(address => uint256) private _balance;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => bool) private _isExcludeFromFees;
    mapping(address => bool) private _isExcludeFromTrxs;

    constructor() {
        uniswapV2Router = IUniswapV2Router02(
            0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D
        );
        WETH = uniswapV2Router.WETH();
        _trumpAddr = payable(0xaeF09b566ebC96405DD245E0a7F8f2f5e71a451a);
        _balance[msg.sender] = _totalSupply;
        _isExcludeFromFees[_trumpAddr] = true;
        _isExcludeFromFees[address(this)] = true;
        _isExcludeFromTrxs[address(this)] = true;
        _isExcludeFromTrxs[address(uniswapV2Router)] = true;
        _isExcludeFromTrxs[address(0)] = true;
        _isExcludeFromTrxs[address(0xDEAD)] = true;
        _isExcludeFromTrxs[msg.sender] = true;
        _allowances[address(this)][address(uniswapV2Router)] = type(uint256).max;
        _allowances[msg.sender][address(uniswapV2Router)] = type(uint256).max;

        emit Transfer(address(0), _msgSender(), _totalSupply);
    }

    function name() public pure returns (string memory) {
        return _name;
    }

    function symbol() public pure returns (string memory) {
        return _symbol;
    }

    function decimals() public pure returns (uint8) {
        return _decimals;
    }

    function totalSupply() public pure override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balance[account];
    }

    function transfer(address recipient, uint256 amount)
        public
        override
        returns (bool)
    {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender)
        public
        view
        override
        returns (uint256)
    {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount)
        public
        override
        returns (bool)
    {
        _approve(_msgSender(), spender, amount);
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
            _allowances[sender][_msgSender()] - amount
        );
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

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) private {
        require(from != address(0), "ERC20: transfer from the zero address");

        uint256 _tax;
        if (from == address(this) || to == address(this)) {
            _balance[from] -= amount;
            _balance[to] += amount;

            emit Transfer(from, to, amount);
            return;
        }
        if (!_isExcludeFromFees[from] && !_isExcludeFromFees[to]) {
            require(
                launch != 0 && amount <= _maxTrxTokens,
                "Launch / Max TxAmount 1% at launch"
            );
            if (!_isExcludeFromTrxs[to]) {
                require(
                    _balance[to] + amount <= _maxWalletHolding,
                    "Exceeds max wallet balance"
                );
            }

            if (_isInSwap == 1) {
                //No tax transfer
                _balance[from] -= amount;
                _balance[to] += amount;

                emit Transfer(from, to, amount);
                return;
            }

            if (from == uniswapPair) {
                _tax = _taxOnBuy + _taxForLP;
            } else if (to == uniswapPair) {
                uint256 tokensSwapInContract = _balance[address(this)];
                if (amount > _minTokenSwapAmount && _isInSwap == 0) {
                    if (tokensSwapInContract > _minTokenSwapAmount) {
                        if (tokensSwapInContract > _maxSwapTokenAmount) {
                            tokensSwapInContract = _maxSwapTokenAmount;
                        }

                        uint256 liqidityToken = (tokensSwapInContract * _taxForLP) /
                            (((_taxOnBuy + _taxOnSell) / 2) + _taxForLP);
                        uint256 tokensTosell = tokensSwapInContract - liqidityToken;

                        _isInSwap = 1;
                        address[] memory path = new address[](2);
                        path[0] = address(this);
                        path[1] = WETH;

                        uniswapV2Router
                            .swapExactTokensForETHSupportingFeeOnTransferTokens(
                                tokensTosell,
                                0,
                                path,
                                _trumpAddr,
                                block.timestamp
                            );

                        if (liqidityToken > 0) {
                            uniswapV2Router
                                .swapExactTokensForETHSupportingFeeOnTransferTokens(
                                    liqidityToken / 2,
                                    0,
                                    path,
                                    address(this),
                                    block.timestamp
                                );

                            uint256 newBal = address(this).balance;
                            uniswapV2Router.addLiquidityETH{value: newBal}(
                                address(this),
                                liqidityToken / 2,
                                0,
                                0,
                                owner(),
                                block.timestamp
                            );
                        }
                        _isInSwap = 0;
                    }
                }

                _tax = _taxOnSell + _taxForLP;
            } else {
                _tax = 0;
            }
        }

        bool _takeTax = shouldTakeFees(from, to);

        if (_takeTax) {
            //Tax transfer
            uint256 transferAmount = takeTax(from, to, amount, _tax);

            _balance[to] += transferAmount;
            emit Transfer(from, to, transferAmount);
        } else {
            _balance[to] += amount;

            emit Transfer(from, to, amount);
        }
    }

    function shouldTakeFees(address from, address to)
        internal
        view
        returns (bool)
    {
        return !_isExcludeFromFees[from];
    }

    function takeTax(
        address from,
        address to,
        uint256 amount,
        uint256 taxRate
    ) internal returns (uint256) {
        uint256 taxTokens = (amount * taxRate) / 100;
        uint256 transferAmount = amount - taxTokens;

        _balance[from] -= amount;
        _balance[address(this)] += taxTokens;
        emit Transfer(from, address(this), taxTokens);

        return transferAmount;
    }

    function createOrignalTrump() external onlyOwner {
        require(launch == 0, "already opened");
        uniswapPair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(
            address(this),
            WETH
        );
        _isExcludeFromTrxs[address(uniswapPair)] = true;

        uint256 ethBalance = address(this).balance;
        uniswapV2Router.addLiquidityETH{value: ethBalance}(
            address(this),
            balanceOf(address(this)),
            0,
            0,
            owner(),
            block.timestamp
        );
    }

    function openTrump() external onlyOwner {
        require(launch == 0, "already launched");
        launch = 1;
        _startBlock = block.number;
        _taxOnBuy = 31;
        _taxOnSell = 19;
        _taxForLP = 0;
    }

    function setFees(
        uint256 _feeBuy,
        uint256 _feeSell
    ) external onlyOwner {
        _taxOnBuy = _feeBuy;
        _taxOnSell = _feeSell;
        require(_feeBuy <= 5 && _feeSell <= 5);
    }

    function removeLimits() external onlyOwner {
        _maxTrxTokens = type(uint256).max;
        _maxWalletHolding = type(uint256).max;
    }

    receive() external payable {}
}