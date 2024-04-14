//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC404Legacy.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract ERC404Orc is ERC404Legacy {
  string public dataURI;
  string public baseTokenURI;
  string public baseExtension = ".json";

  constructor(
    address _owner
  ) ERC404Legacy("404BraveOrc", "404BOrc", 18, 8100, _owner) {
    whitelist[_owner] = true;
    balanceOf[_owner] = 8100 * 10 ** 18;
  }

  function setDataURI(string memory dataURI_) public onlyOwner {
    dataURI = dataURI_;
  }

  function setTokenURI(string memory tokenURI_) public onlyOwner {
    baseTokenURI = tokenURI_;
  }

  function setNameSymbol(string memory name_, string memory symbol_) public onlyOwner {
    _setNameSymbol(name_, symbol_);
  }

  function batchTransfer(address[] memory recipients_, uint256[] memory amount_) public onlyOwner {
    for (uint256 i = 0; i < recipients_.length; i++) {
      transfer(recipients_[i], amount_[i]);
    }
  }

  function tokenURI(uint256 id_) public view override returns (string memory) {
    if (bytes(baseTokenURI).length > 0) {
      return string.concat(baseTokenURI, string.concat(Strings.toString(id_), baseExtension));
    } else {
      return "";
    }
  }  
}
