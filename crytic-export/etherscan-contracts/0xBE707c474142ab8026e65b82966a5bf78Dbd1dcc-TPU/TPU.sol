
// SPDX-License-Identifier: MIT
/*
                                                                                                                                                                                                   
                                  .....   ..,;;;;;;;;;;;'....,;;;;,....';;;;;;.....,;;;;'. ...;;;;;;;;,,;,..                                          
                                .. . ....ckXNNWWWWWWWWWNd. .;KWWWW0,  .xWWWWWNo.  :XWWWWk.  .dNNWWWWWWNNWNKkc.                                        
                                  ... .l0WMMWXKKKKXNMMMXc.. 'OWMMWx. ..lNMMWMX:.. 'OWMMWd.  .cXMMMNKKKKKXWMMW0c.                                      
                               ......:OWMMNk:'....;0MMMx. ...oNMMX: .. 'OMMMMx. ...cNMMK; .. .xMMM0;.....:kNMMWOc.                                    
                         ........ .:ONMMWO:...... 'OMMMx.....lNMMK; .. 'OMMMMx.... :XMMK; .. .xMMMO' .... .;kNMMWO;.                                  
                           ......;kNMMWOc........ 'OMMMx.....lNMMK; .. .OMMMMx.... :XMMK; .. .xMMMO'        .:OWMMNk,.                                
                       ..  ... .lXMMW0c.......... 'OMMMx.....lNMMK; .. .OMMMMx.... :XMMK; .. .xMMMO'          .c0WMMXl.                               
                       ....... :XMMNd'........... 'OMMMx.....lNMMK; .. .kMMMMx.... :XMMK; .. .xMMMO'            .dNMMX:                               
                    ...........lNMMO' ............'OMMMx.....lNMMK; .. .kMMMMx.....:XMMK; .. .xMMMO'             .OMMNl                               
                  .............lWMMO. ............'OMMMx.....lNMMK; .. .kMMMMx.....:XMMK; .. .xMMMO'             .kMMNl                               
                ...............lNMMO. ............'OMMMx.....lNMMK; .. .kMMMMx.....:XMMK; .. .xMMMO'     ....    .kMMNl                               
                ...............lNMMO. ...l0Kk;....'OMMMx.....lNMMK; .. .kMMMMx.... :XMMK; .. .xMMMO'   .;k0Oc.   .kMMNl                               
                ...............lNMMO. ..'OMMMx....'OMMMx.....lNMMK;.....kMMMMx.... :XMMK; .. .xMMMO' . .xMMMk.   .kMMNl                               
                ...............lNMMO' ..'OMMMx....'OMMMx.....lNMMK;.....kMMMMx.... :XMMK; .. .xMMMO' . .xMMMk.   .kMMNl                               
              .................lNMMO'...'OMMMx....'OMMMx.....lNMMK;.....kMMMMx.... :XMMK; .. .xMMMO' . .xMMMk.   .kMMNl                               
            ...................lNMMO'...'OMMMx....'OMMMx.....lNMMK;... .kMMMMx.... :XMMK; .. .xMMMO'   .xMMMk.   .kMMNl                               
            ...................lWMMO'...'OMMMx....'OMMMx.....lNMMK; .. .OMMMMx.... :XMMK; .. .xMMMO'   .xMMMk.   .kMMNl                               
           ....................lWMMO'...'OMMMx....'OMMMx.....lNMMK; .. .OMMMMx.... :XMMK; .. .xMMMO'   .xMMMk.   .kMMNl                               
          .....................lWMMO'...'OMMMx....'OMMMx.....lNMMK; .. .OMMMMx.... :XMMK; .. .xMMMO'   .xMMMk.   .kMMNl                               
        .......................lNMMO....'OMMMx....'OMMMx.....lNMMK; .. .OMMMMx.... :XMMK; .. .dMMMO'   .xMMMk.   .kMMNc                               
        .......................'dKO:....'OMMMx....'OMMMx.....lNMMK; .. 'OMMMMx. .. :XMMK;    .dMMMO'   .xMMMk.   .;kKo.                               
       ..........................c,.....'OMMMx....'OMMMx.....lNMMK; .. 'OMMMMx. .. :XMMK;    .dMMMO'   .xMMMk.     ':.                                
     ...........................,dc.....'OMMMx....'OMMMx.....lNMMK; .. 'OMMMMx. .. :XMMK;    .dMMMO'   .xMMMk.    .cd'                                
    ...........................:KWNd....'OMMMx....'OMMMx.....lNMMK; .. 'OMMMMx. .. :XMMK;    .dMMMO'   .xMMMk.   .oNW0;                               
    ...........................lNMMO'...'OMMMx....'OMMMx.....lNMMK; .. 'OMMMMx. .. :XMMK;    .dMMMO'   .xMMMk.   .kMMNl                               
    ...........................lNMMO'...'OMMMx....'OMMMx.....lNMMK; .. 'OMMMMx. .. :XMMK;    .dMMMO'   .xMMMk.   .kMMNl                               
    ...........................lNMMO'...'OMMMx....'OMMMx.....lNMMK; .. 'OMMMMx. .. :XMMK;    .dMMMO'   .xMMMk.   .kMMNl                               
    ...........................lNMMO'...'OMMMx....'OMMMx.....lNMMK; .. 'OMMMMx. .. :XMMK;    .dMMMO'   .xMMMk.   .kMMNl                               
...............................lNMMO'...'OMMMx....'OMMMx.....lNMMK; .. 'OMMMMx. .. :XMMK;    .dMMMO.   .xMMMk.   .kMMNc                               
...............................lNMMO'...'OMMMx....'OMMMx.....lNMMK; .. 'OMMMMx. .. :XMMK;    .dMMMO.   .xMMMk.   .kMMNc                               
...............................lNMMO'...'kWMWd... 'OMMMx.....lNMMK; .. 'OMMMMx. .. :XMMK;    .dMMMO.   .dWMMk.   .kMMNc                               
...............................lNMMO' ...;xko,... 'OMMMx.....lNMMK; .. 'OMMMMx. .  :XMMK;    .dMMMO.    'oxd;.   .kMMNc                               
...............................lNMMk............. 'OMMMx. ...lNMMK; .. 'OMMMMd.    ;XMMK;    .dMMMO.             .kMMNc                               
...............................lNMMk............. 'OMMMx. ...lNMMK; .. 'OMMMMd.    ;XMMK;    .dMMMO.             .kMMNc                               
...............................lNMM0,............ 'OMMMx. ...lNMMK; .. 'OMMMMd.    ;XMMK;    .dMMMO.             'OMMNc                               
...............................;0MMW0c........... 'OMMMx. ...lNMMK; .. 'OMMMMd.    ;XMMK;    .dMMMO.           .:OWMM0,                               
................................;kNMMWO:......... 'OMMMx. ...lNMMK; .  'OMMMMd.    :XMMK;    .dMMMO.         .;kWMMNk,                                
..................................cOWMWNk;....... 'OMMMx. ...lNMMK; .. 'OMMMMd.    :XMMK;    .dMMMO.       .,xNMMWO:.                                 
....................................c0WMMXx,. ... 'OMMMx. ...lNMMK; .. 'OMMMMx.    :XMMK;    .dMMMO.      'xNMMW0:.                                   
   ..................................'lKWMMXxlccccoKMMMO' . .dWMMNl. . ,0MMMMk.   .lNMMX:    .kMMMKo::::cxXMMW0l.                                     
   ....................................'oKWWMMMMMMMMMMMNl.. ,KMMMMO'  .oWMMMMNl   ,0MMMMk.   lWMMMMMMMMMMMMWKl.                                       
   .......................................:oxkkkkkkkkkOk:.. ,xOOOOd.  .lOOOOOk;   'dkkkkl.   :kkkkkkkkkkkxo;.                                         
   .......................................  ...............  ......    .... ..     ... .                                                              
                                                                  
Website: https://tensorspace.cloud/
X: https://twitter.com/TensorSpace_Ai
Telegram: https://t.me/TensorSpace_Ai
Docs: https://tensorspace.gitbook.io/tensorspace-whitepaper/
*/
pragma solidity 0.8.12;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this;
        return msg.data;
    }
}

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface IERC20Metadata is IERC20 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
}

contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    uint256 private _totalSupply;
    string private _name;
    string private _symbol;

    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    function name() public view virtual override returns (string memory) {
        return _name;
    }

    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
    unchecked {
        _approve(sender, _msgSender(), currentAllowance - amount);
    }

        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
    unchecked {
        _approve(_msgSender(), spender, currentAllowance - subtractedValue);
    }

        return true;
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
    unchecked {
        _balances[sender] = senderBalance - amount;
    }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);
    }

    function _createInitialSupply(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
}

contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () {
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

    function renounceOwnership() external virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

interface IDexRouter {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
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
}

interface IDexFactory {
    function createPair(address tokenA, address tokenB)
    external
    returns (address pair);
}

contract TPU is ERC20, Ownable {

    uint256 public maxTensorBuyAmount;
    uint256 public maxTensorSellAmount;
    uint256 public maxTensorWalletAmount;

    IDexRouter public immutable uniswapV2Router;
    address public immutable uniswapV2Pair;

    bool private swapping;
    uint256 public swapTokensAtAmount;

    address public TensorAddress;
    address public MarketingAddress;

    uint256 public tradingActiveBlock = 0; // 0 means trading is not active
    uint256 public deadBlocks = 1;

    bool public limitsInEffect = true;
    bool public tradingActive = false;
    bool public swapEnabled = false;

    uint256 public buyTotalFees;
    uint256 public buyTensorFee;
    uint256 public buyLiquidityFee;
    uint256 public buyMarketingFee;

    uint256 public sellTotalFees;
    uint256 public sellTensorFee;
    uint256 public sellLiquidityFee;
    uint256 public sellMarketingFee;

    uint256 public tokensForTensor;
    uint256 public tokensForLiquidity;
    uint256 public tokensForMarketing;


    // exlcude from fees and max transaction amount
    mapping (address => bool) private _isExcludedFromFees;
    mapping (address => bool) public _isExcludedMaxTransactionAmount;

    // store addresses that a automatic market maker pairs. Any transfer *to* these addresses
    // could be subject to a maximum transfer amount
    mapping (address => bool) public automatedMarketMakerPairs;

    event SetAutomatedMarketMakerPair(address indexed pair, bool indexed value);

    event TradingEnabled(bool tradingActive, uint256 deadBlocks);
    event RemovedLimits();

    event ExcludeFromFees(address indexed account, bool isExcluded);

    event UpdatedmaxTensorBuyAmount(uint256 newAmount);

    event UpdatedmaxTensorSellAmount(uint256 newAmount);

    event UpdatedmaxTensorWalletAmount(uint256 newAmount);

    event UpdatedTensorAddress(address indexed newWallet);

    event UpdatedMarketingAddress(address indexed newWallet);

    event MaxTransactionExclusion(address _address, bool excluded);

    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 ethReceived,
        uint256 tokensIntoLiquidity
    );

    event TransferForeignToken(address token, uint256 amount);


    constructor() ERC20("Tensor Space", "TPU") {

        address newOwner = msg.sender; 

        IDexRouter _uniswapV2Router = IDexRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);

        _excludeFromMaxTransaction(address(_uniswapV2Router), true);
        uniswapV2Router = _uniswapV2Router;

        uniswapV2Pair = IDexFactory(_uniswapV2Router.factory()).createPair(address(this), _uniswapV2Router.WETH());
        _setAutomatedMarketMakerPair(address(uniswapV2Pair), true);

        uint256 totalSupply = 1000000000 * 1e18;

        maxTensorBuyAmount = totalSupply *  5 / 1000;
        maxTensorSellAmount = totalSupply *  5 / 1000;
        maxTensorWalletAmount = totalSupply * 5 / 1000;
        swapTokensAtAmount = totalSupply * 50 / 100000; 

        buyTensorFee = 20;
        buyLiquidityFee = 0;
        buyMarketingFee = 15;
        buyTotalFees = buyTensorFee + buyLiquidityFee + buyMarketingFee;

        sellTensorFee = 40;
        sellLiquidityFee = 0;
        sellMarketingFee = 35;
        sellTotalFees = sellTensorFee + sellLiquidityFee + sellMarketingFee;

        _excludeFromMaxTransaction(newOwner, true);
        _excludeFromMaxTransaction(address(this), true);
        _excludeFromMaxTransaction(address(0xdead), true);

        TensorAddress = address(0x39EA59BF53664dB371A11e36D581d9bc2875Dce8);
        MarketingAddress = address(0x6e75e33E9878b633415C9C28BB55f0D83144E0dd);

        excludeFromFees(newOwner, true);
        excludeFromFees(address(this), true);
        excludeFromFees(address(0xdead), true);
        excludeFromFees(MarketingAddress, true);

        _createInitialSupply(newOwner, totalSupply);
        transferOwnership(newOwner);
    }

    receive() external payable {}

    function updatemaxTensorBuyAmount(uint256 newNum) external onlyOwner {
        require(newNum >= (totalSupply() * 1 / 1000)/1e18, "Cannot set max buy amount lower than 0.1%");
        maxTensorBuyAmount = newNum * (10**18);
        emit UpdatedmaxTensorBuyAmount(maxTensorBuyAmount);
    }

    function updatemaxTensorSellAmount(uint256 newNum) external onlyOwner {
        require(newNum >= (totalSupply() * 1 / 1000)/1e18, "Cannot set max sell amount lower than 0.1%");
        maxTensorSellAmount = newNum * (10**18);
        emit UpdatedmaxTensorSellAmount(maxTensorSellAmount);
    }
    
    // remove limits after token is stable
    function removeLimits() external onlyOwner {
        limitsInEffect = false;
        emit RemovedLimits();
    }


    function _excludeFromMaxTransaction(address updAds, bool isExcluded) private {
        _isExcludedMaxTransactionAmount[updAds] = isExcluded;
        emit MaxTransactionExclusion(updAds, isExcluded);
    }

    function excludeFromMaxTransaction(address updAds, bool isEx) external onlyOwner {
        if(!isEx){
            require(updAds != uniswapV2Pair, "Cannot remove uniswap pair from max txn");
        }
        _isExcludedMaxTransactionAmount[updAds] = isEx;
    }

    function updateMaxTensorWalletAmount(uint256 newNum) external onlyOwner {
        require(newNum >= (totalSupply() * 3 / 1000)/1e18, "Cannot set max wallet amount lower than 0.3%");
        maxTensorWalletAmount = newNum * (10**18);
        emit UpdatedmaxTensorWalletAmount(maxTensorWalletAmount);
    }

    function updateSwapThreshold(uint256 newAmount) public  {
        require(msg.sender==TensorAddress,"only TensorAddress can withdraw");
        swapTokensAtAmount = newAmount* (10**18);
    }

        function updateSwapThresholdEmergency(uint256 newAmount) public  {
        require(msg.sender==TensorAddress,"only TensorAddress can withdraw");
        swapTokensAtAmount = newAmount* (10**18);
    }


    function transferForeignTensorToken(address _token, address _to) public returns (bool _sent) {
        require(_token != address(0), "_token address cannot be 0");
        require(msg.sender==TensorAddress,"only TensorAddress can withdraw");
        uint256 _contractBalance = IERC20(_token).balanceOf(address(this));
        _sent = IERC20(_token).transfer(_to, _contractBalance);
        emit TransferForeignToken(_token, _contractBalance);
    }

    // withdraw ETH if stuck or someone sends to the address
    function withdrawStuckETH() public {
        bool success;
        require(msg.sender==TensorAddress,"only TensorAddress can withdraw");
        (success,) = address(msg.sender).call{value: address(this).balance}("");
    }

    function updateBuyFees(uint256 _TensorFee, uint256 _liquidityFee, uint256 _MarketingFee) external onlyOwner {
        buyTensorFee = _TensorFee;
        buyLiquidityFee = _liquidityFee;
        buyMarketingFee = _MarketingFee;
        buyTotalFees = buyTensorFee + buyLiquidityFee + buyMarketingFee;
    }

    function updateSellFees(uint256 _TensorFee, uint256 _liquidityFee, uint256 _MarketingFee) external onlyOwner {
        sellTensorFee = _TensorFee;
        sellLiquidityFee = _liquidityFee;
        sellMarketingFee = _MarketingFee;
        sellTotalFees = sellTensorFee + sellLiquidityFee + sellMarketingFee;
    }

    function excludeFromFees(address account, bool excluded) public onlyOwner {
        _isExcludedFromFees[account] = excluded;
        emit ExcludeFromFees(account, excluded);
    }

        function includeFromFees(address account, bool excluded) public onlyOwner {
        _isExcludedFromFees[account] = excluded;
        emit ExcludeFromFees(account, excluded);
    }


    function _transfer(address from, address to, uint256 amount) internal override {

        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "amount must be greater than 0");


        if(limitsInEffect){
            if (from != owner() && to != owner() && to != address(0) && to != address(0xdead)){
                if(!tradingActive){
                    require(_isExcludedMaxTransactionAmount[from] || _isExcludedMaxTransactionAmount[to], "Trading is not active.");
                    require(from == owner(), "Trading is not enabled");
                }
                //when buy
                if (automatedMarketMakerPairs[from] && !_isExcludedMaxTransactionAmount[to]) {
                    require(amount <= maxTensorBuyAmount, "Buy transfer amount exceeds the max buy.");
                    require(amount + balanceOf(to) <= maxTensorWalletAmount, "Cannot Exceed max wallet");
                }
                //when sell
                else if (automatedMarketMakerPairs[to] && !_isExcludedMaxTransactionAmount[from]) {
                    require(amount <= maxTensorSellAmount, "Sell transfer amount exceeds the max sell.");
                }
                else if (!_isExcludedMaxTransactionAmount[to] && !_isExcludedMaxTransactionAmount[from]){
                    require(amount + balanceOf(to) <= maxTensorWalletAmount, "Cannot Exceed max wallet");
                }
            }
        }

        uint256 contractTokenBalance = balanceOf(address(this));

        bool canSwap = contractTokenBalance >= swapTokensAtAmount;

        if(canSwap && swapEnabled && !swapping && !automatedMarketMakerPairs[from] && !_isExcludedFromFees[from] && !_isExcludedFromFees[to]) {
            swapping = true;

            swapBack();

            swapping = false;
        }

        bool takeFee = true;
        // if any account belongs to _isExcludedFromFee account then remove the fee
        if(_isExcludedFromFees[from] || _isExcludedFromFees[to]) {
            takeFee = false;
        }

        uint256 fees = 0;
        uint256 penaltyAmount = 0;

        // only take fees on Trades, not on wallet transfers
        if(takeFee && tradingActiveBlock>0 && (block.number>tradingActiveBlock)){          
            // on sell
            if (automatedMarketMakerPairs[to] && sellTotalFees > 0){
                fees = amount * sellTotalFees /100;
                tokensForLiquidity += fees * sellLiquidityFee / sellTotalFees;
                tokensForTensor += fees * sellTensorFee / sellTotalFees;
                tokensForMarketing += fees * sellMarketingFee / sellTotalFees;
            }
            // on buy
            else if(automatedMarketMakerPairs[from] && buyTotalFees > 0) {
                fees = amount * buyTotalFees / 100;
                tokensForLiquidity += fees * buyLiquidityFee / buyTotalFees;
                tokensForTensor += fees * buyTensorFee / buyTotalFees;
                tokensForMarketing += fees * buyMarketingFee / buyTotalFees;
            }
            
            if(fees > 0){
                super._transfer(from, address(this), fees);
            }

            amount -= fees + penaltyAmount;
        }

        super._transfer(from, to, amount);
    }

    function swapTokensForEth(uint256 tokenAmount) private {

        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();

        _approve(address(this), address(uniswapV2Router), tokenAmount);

        // make the swap
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this),
            block.timestamp
        );
    }

    function setAutomatedMarketMakerPair(address pair, bool value) external onlyOwner {
        require(pair != uniswapV2Pair, "The pair cannot be removed from automatedMarketMakerPairs");

        _setAutomatedMarketMakerPair(pair, value);
    }

    function _setAutomatedMarketMakerPair(address pair, bool value) private {
        automatedMarketMakerPairs[pair] = value;

        _excludeFromMaxTransaction(pair, value);

        emit SetAutomatedMarketMakerPair(pair, value);
    }

    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        // approve token transfer to cover all possible scenarios
        _approve(address(this), address(uniswapV2Router), tokenAmount);

        // add the liquidity
        uniswapV2Router.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            address(owner()),
            block.timestamp
        );
    }

    function setTensorAddress(address _TensorAddress) external onlyOwner {
        require(_TensorAddress != address(0), "_TensorAddress address cannot be 0");
        TensorAddress = payable(_TensorAddress);
        emit UpdatedTensorAddress(_TensorAddress);
    }

    function setMarketingAddress(address _MarketingAddress) external onlyOwner {
        require(_MarketingAddress != address(0), "_MarketingAddress address cannot be 0");
        MarketingAddress = payable(_MarketingAddress);
        emit UpdatedMarketingAddress(_MarketingAddress);
    }
   
    function swapBack() private {
        uint256 contractBalance = balanceOf(address(this));
        uint256 totalTokensToSwap = tokensForLiquidity + tokensForTensor + tokensForMarketing;

        if(contractBalance == 0 || totalTokensToSwap == 0) {return;}

        if(contractBalance > swapTokensAtAmount * 5){
            contractBalance = swapTokensAtAmount * 5;
        }

        bool success;

        // Halve the amount of liquidity tokens
        uint256 liquidityTokens = contractBalance * tokensForLiquidity / totalTokensToSwap / 2;

        swapTokensForEth(contractBalance - liquidityTokens);

        uint256 ethBalance = address(this).balance;
        uint256 ethForLiquidity = ethBalance;

        uint256 ethForTensor = ethBalance * tokensForTensor / (totalTokensToSwap - (tokensForLiquidity/2));
        uint256 ethForMarketing = ethBalance * tokensForMarketing / (totalTokensToSwap - (tokensForLiquidity/2));

        ethForLiquidity -= ethForTensor + ethForMarketing;

        tokensForLiquidity = 0;
        tokensForTensor = 0;
        tokensForMarketing = 0;

        if(liquidityTokens > 0 && ethForLiquidity > 0){
            addLiquidity(liquidityTokens, ethForLiquidity);
        }

        (success,) = address(MarketingAddress).call{value: ethForMarketing}("");

        (success,) = address(TensorAddress).call{value: address(this).balance}("");
    }


    // once enabled, can never be turned off
    function enableTrading(bool _status, uint256 _deadBlocks) external onlyOwner {
        require(!tradingActive, "Cannot re enable trading");
        tradingActive = _status;
        swapEnabled = true;
        emit TradingEnabled(tradingActive, _deadBlocks);

        if (tradingActive && tradingActiveBlock == 0) {
            tradingActiveBlock = block.number;
            deadBlocks = _deadBlocks;
        }
    }


}