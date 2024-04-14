pragma solidity ^ 0.8.24;

contract ERC20 {

    function name() external pure returns (string memory) { return "ERC20 Token"; }
    function symbol() external pure returns (string memory) { return "ERC20"; }
    function decimals() external pure returns (uint8) { return 18; }
    function totalSupply() external pure returns (uint) { return 1e18 * 1e6; }
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint)) public allowance;

    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);

    constructor() {balanceOf[msg.sender] = 1e18 * 1e6;}

    function transfer(address to, uint amount) external {
        balanceOf[msg.sender] -= amount;
        balanceOf[to] += amount;
        emit Transfer(msg.sender, to, amount);
    }

    function transferFrom(address from, address to, uint amount) external {
        allowance[from][msg.sender] -= amount;
        balanceOf[from] -= amount;
        balanceOf[to] += amount;
        emit Transfer(from, to, amount);
    }

    function approve(address spender, uint amount) external {
        allowance[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
    }

}