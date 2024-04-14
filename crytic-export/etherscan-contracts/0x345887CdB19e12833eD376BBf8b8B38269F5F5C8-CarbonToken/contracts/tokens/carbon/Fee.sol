// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";

// Carbon & LightLink 2023

interface IFee {
  function masterAccount() external view returns (address);

  function extractFee(address _sender, uint256 _amount) external view returns (uint256 fee, uint256 sendAmount);
}

contract CarbonTokenFee is Ownable, IFee {
  address public masterAccount = 0x2C8EEDA98a84a393e2DB66B013A0cDCA2F3693f2;
  uint256 public feeRate = 250;

  mapping(address => bool) public feeAddressList;

  constructor() {
    feeAddressList[0x68b3465833fb72A70ecDF485E0e4C7bD8665Fc45] = true;
    feeAddressList[0xE592427A0AEce92De3Edee1F18E0157C05861564] = true;
  }

  function extractFee(address _sender, uint256 amount) public view returns (uint256, uint256) {
    if (!feeAddressList[_sender]) {
      return (0, amount);
    }
    uint256 fee = (amount * feeRate) / 10000;
    return (fee, amount - fee);
  }

  /* Admin */
  function setMasterAccount(address _account) public onlyOwner {
    masterAccount = _account;
  }

  function setFeeRate(uint256 _rate) public onlyOwner {
    require(_rate <= 10000, "Exceed max");
    feeRate = _rate;
  }

  function setFeeAddressList(address[] calldata _accounts, bool[] calldata _status) public onlyOwner {
    require(_accounts.length == _status.length, "Invalid input");
    for (uint256 i = 0; i < _accounts.length; i++) {
      feeAddressList[_accounts[i]] = _status[i];
    }
  }

  function withdraw() public onlyOwner {
    uint256 balance = address(this).balance;
    payable(msg.sender).transfer(balance);
  }
}
