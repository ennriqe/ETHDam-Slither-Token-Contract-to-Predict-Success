// SPDX-License-Identifier: MIT
// _totalSupply

pragma solidity 0.8.24;

import "./AccessControl.sol";
import "./Ownable2Step.sol";
import "./ERC20.sol";

contract pAuri is ERC20, Ownable2Step, Blacklistable, Pausable {
    address public _pauser;

    event PauserChanged(address newPauser);
    event ContractPauseStatus(bool status);

    modifier checkAddressZero(address _wallet) {
        if(_wallet == address(0)) {
            revert("Can't set zero address");
        }
        _;
    }

    constructor(address pauser_, address blacklister_, address initialOwner_) ERC20("Precursor AURI", "pAURI") Ownable2Step(initialOwner_) checkAddressZero(initialOwner_) {
        _pauser = pauser_;
        blacklister = blacklister_;
        // Token generation - only called once when deploying
        // Supply fixed at 1 billion tokens
        _mint(initialOwner_, 1e9 * 1e18);
    }

    modifier onlyPauser() {
        require(msg.sender == _pauser);
        _;
    }

    function updateBlacklister(address _newBlacklister) external onlyOwner checkAddressZero(_newBlacklister){
        blacklister = _newBlacklister;
        emit BlacklisterChanged(blacklister);
    }

    function updatePauser(address newPauser) external onlyOwner checkAddressZero(newPauser) {

        _pauser = newPauser;

        emit PauserChanged(newPauser);
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override whenNotPaused {
        require(from != address(0x0), "ERC20: transfer from the zero address");
        require(to != address(0x0), "ERC20: transfer to the zero address");

        if (blacklisted[from] || blacklisted[to]) {
            revert("Transfer not allowed for blacklisted addresses");
        }

        super._transfer(from, to, amount);
    }

    /**
     * @notice Pause the contract, stops all transfers.
     * @param status bool
     */
    function togglePause(bool status) external onlyPauser {
        if (status && !_paused) {
            _pause();
        } else if (_paused){
            _unpause();
        }

        emit ContractPauseStatus(status);
    }

    /**
     * @notice Rescue ERC20 tokens locked up in this contract.
     * @param tokenContract ERC20 token contract address
     * @param to Recipient address
     */
    function rescueERC20(IERC20 tokenContract, address to) external onlyOwner {
        require(
            to != address(0),
            "Error: Receiver address can't be zero address. What is the point of rescue?"
        );
        if (tokenContract == IERC20(address(0))) {
            payable(to).transfer(address(this).balance);
        } else {
            uint256 withdrawableAmount = tokenContract.balanceOf(address(this));
            tokenContract.transfer(to, withdrawableAmount);
        }
    }
}
