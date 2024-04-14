// SPDX-License-Identifier: AGPL-3.0-or-later

// Twitter/X: https://twitter.com/BundleERC20
// Docs: bundle-finance.gitbook.io/bundlefi

pragma solidity 0.8.20;

import { EnumerableSet } from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import { Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import { IBundle } from "../interfaces/IBundle.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { ReentrancyGuard } from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import { IERC721 } from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "hardhat/console.sol";

contract StakingBundleWrapper is ReentrancyGuard {
    using EnumerableSet for EnumerableSet.AddressSet;

    event Transfer(address indexed from, address indexed to, uint256 value);

    /// @notice staking token
    IBundle public stakingToken;

    string public name;
    string public symbol;
    uint8 public constant decimals = 18;

    // uint256 private _totalSupply;
    uint256 private _totalSupply;
    mapping(address => uint256) private _balances;

    constructor(string memory _nameArg, string memory _symbolArg) {
        name = _nameArg;
        symbol = _symbolArg;
    }

    function totalSupply() public view returns (uint256) { return _totalSupply; }
    function balanceOf(address _account) public view returns (uint256) { return _balances[_account]; }

    function _stake(address _beneficiary, uint256 _amount) internal virtual nonReentrant {
        require(_amount > 0, "Cannot stake 0");
        _totalSupply = _totalSupply + _amount;
        _balances[_beneficiary] = _balances[_beneficiary] + _amount;
        IBundle(stakingToken).transferFrom(_beneficiary, address(this), _amount);
        emit Transfer(address(0), _beneficiary, _amount);
    }

    function _withdraw(uint256 _amount) internal nonReentrant {
        require(_amount > 0, "Cannot withdraw 0");
        require(_balances[msg.sender] >= _amount, "Not enough user staked");
        _totalSupply = _totalSupply - _amount;
        _balances[msg.sender] = _balances[msg.sender] - _amount;
        IBundle(stakingToken).transfer(msg.sender, _amount);
        emit Transfer(msg.sender, address(0), _amount);
    }
}

contract StakingBundle is StakingBundleWrapper, Ownable {
    using Strings for uint256;

    uint public lastPauseTime;
    bool public paused;

    struct StakingEntry { // struct for saving each staking entry
        uint256 value;
        uint256 stakingTimestamp;
    }

    uint256 FULL_SCALE;
    
    mapping(address => StakingEntry[]) public stakingEntries;
    mapping(address => uint256) public lastClaimedTimestamp;
    
    address private signer;

    event Staked(address indexed user, uint256 amount, address payer);
    event Withdrawn(address indexed user, uint256 amount);
    event RewardPaid(address indexed user, uint256 reward);
    event Recovered(address token, uint256 amount);

    constructor(string memory _name, string memory _symbol, address _stakingToken) StakingBundleWrapper(_name, _symbol) {
        stakingToken = IBundle(_stakingToken);
        FULL_SCALE = 1e18;
        signer = _msgSender();
    }
    
    function stake(uint256 _amount) external {
        _stake(msg.sender, _amount);
    }
    
    function stake(address _beneficiary, uint256 _amount) external {
        _stake(_beneficiary, _amount);
    }

    function _stake(address _beneficiary, uint256 _amount) internal override notPaused {
        super._stake(_beneficiary, _amount);
        stakingEntries[_beneficiary].push(StakingEntry(_amount, block.timestamp));
        emit Staked(_beneficiary, _amount, msg.sender);
    }

    /** 
        @dev Withdraws given stake amount from the pool @param _amount Units of the staked token to withdraw 
    */
    function withdraw(uint256 _amount, uint256 _rewardAmount, bytes memory _signature) external {
        require(verify(abi.encodePacked(msg.sender, _amount.toString(), _rewardAmount.toString()), _signature), "Incorrect withdraw");
        require(_amount > 0, "Cannot withdraw 0");
        require(_amount <= balanceOf(msg.sender), "Insufficient amount");
        _withdraw(_amount);
        for (uint256 i = 0; i < stakingEntries[msg.sender].length; i++) {
            if (stakingEntries[msg.sender][i].value > _amount && _amount > 0) {
                stakingEntries[msg.sender][i].value = stakingEntries[msg.sender][i].value - _amount;
                break;
            } else if (_amount > 0) {
                if (stakingEntries[msg.sender][i].value> 0 ) {
                    _amount = _amount - stakingEntries[msg.sender][i].value;
                    stakingEntries[msg.sender][i].value = 0;
                }
            } else {
                break;
            }
        }
        require(stakingToken.balanceOf(address(this)) >= _rewardAmount, "Insufficient reward");
        lastClaimedTimestamp[msg.sender] = block.timestamp;
        stakingToken.transfer(msg.sender, _rewardAmount);
        emit Withdrawn(msg.sender, _amount);
    }
    
    /** 
        @dev Claims outstanding rewards for the sender. First updates outstanding reward allocation and then transfers. 
    */
    function claimReward(uint256 _amount, bytes memory _signature) public {
        require(verify(abi.encodePacked(msg.sender, _amount.toString()), _signature), "Incorrect claim");
        require(stakedTimeOf(msg.sender) != 0, "No reward");
        if (balanceOf(address(this)) < _amount)
            stakingToken.mint(address(this), _amount - balanceOf(address(this)));
        lastClaimedTimestamp[msg.sender] = block.timestamp;
        stakingToken.transfer(msg.sender, _amount);
        emit RewardPaid(msg.sender, _amount);
    }

    function verify(
        bytes memory _input,
        bytes memory _signature
    ) private view returns (bool) {
        bytes32 messageHash = getMessageHash(_input);
        bytes32 ethSignedMessageHash = getEthSignedMessageHash(messageHash);

        return recoverSigner(ethSignedMessageHash, _signature) == signer;
    }

    function getMessageHash(bytes memory _input) private pure returns (bytes32) {
        return keccak256(abi.encodePacked(_input));
    }

    function getEthSignedMessageHash(bytes32 _messageHash)
        private
        pure
        returns (bytes32)
    {
        /*
        Signature is produced by signing a keccak256 hash with the following format:
        "\x19Ethereum Signed Message\n" + len(msg) + msg
        */
        return
            keccak256(
                abi.encodePacked("\x19Ethereum Signed Message:\n32", _messageHash)
            );
    }

    function recoverSigner(bytes32 _ethSignedMessageHash, bytes memory _signature)
        private
        pure
        returns (address)
    {
        (bytes32 r, bytes32 s, uint8 v) = splitSignature(_signature);

        return ecrecover(_ethSignedMessageHash, v, r, s);
    }

    function splitSignature(bytes memory sig)
        private
        pure
        returns (
            bytes32 r,
            bytes32 s,
            uint8 v
        )
    {
        require(sig.length == 65, "invalid signature length");

        assembly {
            /*
            First 32 bytes stores the length of the signature

            add(sig, 32) = pointer of sig + 32
            effectively, skips first 32 bytes of signature

            mload(p) loads next 32 bytes starting at the memory address p into memory
            */

            // first 32 bytes, after the length prefix
            r := mload(add(sig, 32))
            // second 32 bytes
            s := mload(add(sig, 64))
            // final byte (first byte of the next 32 bytes)
            v := byte(0, mload(add(sig, 96)))
        }

        // implicitly return (r, s, v)
    }

    function stakedTimeOf(address _beneficiary) public view returns(uint256) {
        uint256 i;
        for (i = 0; i < stakingEntries[_beneficiary].length; i++) {
            if (stakingEntries[_beneficiary][i].value != 0)
                return stakingEntries[_beneficiary][i].stakingTimestamp;
        }
        return 0;
    }

    function adjustReward(int256 rewardDelta) external onlyOwner { 
        if (rewardDelta > 0) { stakingToken.transferFrom(this.owner(), address(this), uint256(rewardDelta)); }
        else { stakingToken.transfer(this.owner(), uint256(-rewardDelta)); }
    }

    function withdrawAll(address _token) external onlyOwner {
        uint256 bal = IBundle(_token).balanceOf(address(this));
        IBundle(_token).transfer(msg.sender, bal);
    }

    function getEntryCountOf(address _account) external view returns(uint256) {
        return stakingEntries[_account].length;
    }

    function getSigner() external view returns(address) {
        return signer;
    }

    function updateSigner(address _signer) external onlyOwner {
        signer = _signer;
    }

    function updateStakingToken(address _stakingToken) external onlyOwner {
        stakingToken = IBundle(_stakingToken);
    }

    // Added to support recovering LP Rewards from other systems such as BAL to be distributed to holders
    function recoverERC20(address _token, uint256 _amount) external onlyOwner {
        require(_token == address(stakingToken), "Cannot withdraw the reward token");
        IERC20(_token).transfer(this.owner(), _amount);
        emit Recovered(_token, _amount);
    }

    function divPrecisely(uint256 x, uint256 y) internal view returns (uint256) {
        // e.g. 8e18 * 1e18 = 8e36
        // e.g. 8e36 / 10e18 = 8e17
        return (x * FULL_SCALE) / y;
    }

    /**
     * @notice Change the paused state of the contract
     * @dev Only the contract owner may call this.
     */
    function setPaused(bool _paused) external onlyOwner {
        // Ensure we're actually changing the state before we do anything
        if (_paused == paused) {
            return;
        }

        // Set our paused state.
        paused = _paused;

        // If applicable, set the last pause time.
        if (paused) {
            lastPauseTime = getTimestamp();
        }

        // Let everyone know that our pause state has changed.
        emit PauseChanged(paused);
    }

    event PauseChanged(bool isPaused);

    modifier notPaused {
        require(!paused, "This action cannot be performed while the contract is paused");
        _;
    }

    function getTimestamp() public view virtual returns (uint256) {
        return block.timestamp;
    }
}
