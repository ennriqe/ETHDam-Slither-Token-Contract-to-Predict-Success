// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {
    function transfer(address to, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}

contract AiDAO {
    string public constant name = "AiDAO";
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;
    address public owner;
    uint256 public royaltyFee = 3; // 3% royalty fee

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event RoyaltyFeePaid(address indexed owner, uint256 value);

    constructor(
        string memory _symbol,
        uint8 _decimals,
        uint256 _initialSupply
    ) {
        symbol = _symbol;
        decimals = _decimals;
        totalSupply = _initialSupply * (10 ** uint256(_decimals));
        balanceOf[msg.sender] = totalSupply;
        owner = msg.sender;
        emit Transfer(address(0), msg.sender, totalSupply);
    }

    function transfer(address _to, uint256 _value) external returns (bool) {
        require(_to != address(0), "ERC20: transfer to the zero address");
        require(_value <= balanceOf[msg.sender], "ERC20: transfer amount exceeds balance");

        uint256 royaltyAmount = (_value * royaltyFee) / 100;
        uint256 amountAfterRoyalty = _value - royaltyAmount;

        balanceOf[msg.sender] -= _value;
        balanceOf[_to] += amountAfterRoyalty;
        balanceOf[owner] += royaltyAmount;

        emit Transfer(msg.sender, _to, amountAfterRoyalty);
        emit RoyaltyFeePaid(owner, royaltyAmount);

        return true;
    }

    function approve(address _spender, uint256 _value) external returns (bool) {
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) external returns (bool) {
        require(_to != address(0), "ERC20: transfer to the zero address");
        require(_value <= balanceOf[_from], "ERC20: transfer amount exceeds balance");
        require(_value <= allowance[_from][msg.sender], "ERC20: transfer amount exceeds allowance");

        uint256 royaltyAmount = (_value * royaltyFee) / 100;
        uint256 amountAfterRoyalty = _value - royaltyAmount;

        balanceOf[_from] -= _value;
        balanceOf[_to] += amountAfterRoyalty;
        balanceOf[owner] += royaltyAmount;
        allowance[_from][msg.sender] -= _value;

        emit Transfer(_from, _to, amountAfterRoyalty);
        emit RoyaltyFeePaid(owner, royaltyAmount);

        return true;
    }
}