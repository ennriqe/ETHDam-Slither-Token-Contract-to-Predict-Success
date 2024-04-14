// SPDX-License-Identifier: MIT
pragma solidity >=0.8.16;

import {Initializable} from "@openzeppelin-upgradeable-contracts/proxy/utils/Initializable.sol";
import {UUPSUpgradeable} from "@openzeppelin-upgradeable-contracts/proxy/utils/UUPSUpgradeable.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {MessageHashUtils} from "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {IVoteLocker} from "src/interfaces/IVoteLocker.sol";
import {IGaugeController} from "src/interfaces/Gauge/IGaugeController.sol";
import {IMinter} from "src/interfaces/Minter/IMinter.sol";
import {IMinterEscrow} from "src/interfaces/Minter/IMinterEscrow.sol";

import {IRegistryContract} from "src/interfaces/Registry/IRegistryContract.sol";

import {IRegistryAccess} from "src/interfaces/Registry/IRegistryAccess.sol";

import {
    CONTRACT_REGISTRY_ACCESS,
    WEEK,
    CONTRACT_GAUGE_CONTROLLER,
    ROLE_OPAL_TEAM
} from "src/utils/constants.sol";

contract LiquidityGauge is Initializable, UUPSUpgradeable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    // Constants

    uint256 public constant TOKENLESS_PRODUCTION = 40;

    uint256 public constant MAX_RELATIVE_WEIGHT_CAP = 10 ** 18;

    bytes32 public constant ERC1271_MAGIC_VAL =
        0x1626ba7e00000000000000000000000000000000000000000000000000000000;
    bytes32 public constant EIP712_TYPEHASH = keccak256(
        "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
    );
    bytes32 public constant PERMIT_TYPEHASH = keccak256(
        "Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"
    );
    string public constant VERSION = "v1.0.0";

    uint256 constant MAX_UINT256 = type(uint256).max;

    // Storage

    address public MINTER;
    address public MINTER_ESCROW;
    address public VL_TOKEN;
    address public GAUGE_CONTROLLER;

    IRegistryContract public registryContract;
    IRegistryAccess public registryAccess;

    mapping(address => uint256) public nonces;

    address public lpToken;
    uint256 public futureEpochTime;

    mapping(address => uint256) public balanceOf;
    uint256 public totalSupply;
    mapping(address => mapping(address => uint256)) allowance;

    string public name;
    string public symbol;

    mapping(address => uint256) public workingBalances;
    uint256 public workingSupply;

    // The goal is to be able to calculate ∫(rate * balance / totalSupply dt) from 0 till checkpoint
    // All values are kept in units of being multiplied by 1e18
    uint256 public period;
    uint256[] public periodTimestamp;

    // 1e18 * ∫(rate(t) / totalSupply(t) dt) from 0 till checkpoint
    uint256[] public integrateInvSupply; // bump epoch when rate() changes
    uint256[] public integrateInvSupplyBoosted; // bump epoch when rate() changes

    // 1e18 * ∫(rate(t) / totalSupply(t) dt) from (last_action) till checkpoint
    mapping(address => uint256) public integrateInvSupplyOf;
    mapping(address => uint256) public integrateCheckpointOf;
    mapping(address => uint256) public integrateBoostedInvSupplyOf;
    mapping(address => uint256) public integrateBoostedCheckpointOf;

    // ∫(balance * rate(t) / totalSupply(t) dt) from 0 till checkpoint
    // Units: rate * t = already number of coins per address to issue
    mapping(address => uint256) public integrateFraction;
    mapping(address => uint256) public integrateFractionBoosted;

    uint256 public inflationRate;
    uint256 public inflationRateBoosted;

    bool public isKilled;
    address public factory;

    // Events

    event Deposit(address indexed provider, uint256 value);

    event Withdraw(address indexed provider, uint256 value);

    event UpdateLiquidityLimit(
        address indexed user,
        uint256 original_balance,
        uint256 original_supply,
        uint256 working_balance,
        uint256 working_supply
    );

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);

    // Errors

    error CannotInitialize();
    error CallerNotAllowed();
    error NotAllowed();
    error AddressZero();
    error SignatureExpired();
    error SignatureInvalid();

    modifier onlyOpalTeam() {
        if (!registryAccess.checkRole(ROLE_OPAL_TEAM, msg.sender)) revert NotAllowed();
        _;
    }

    // Constructor

    constructor() {
        _disableInitializers();
    }

    function initialize(
        address _minter,
        address _minterEscrow,
        address _vlToken,
        address _registryContract
    ) public initializer {
        __UUPSUpgradeable_init();
        MINTER = _minter;
        MINTER_ESCROW = _minterEscrow;
        VL_TOKEN = _vlToken;
        registryContract = IRegistryContract(_registryContract);
        registryAccess = IRegistryAccess(registryContract.getContract(CONTRACT_REGISTRY_ACCESS));

        GAUGE_CONTROLLER = registryContract.getContract(CONTRACT_GAUGE_CONTROLLER);

        lpToken = address(0x000000000000000000000000000000000000dEaD);
    }

    /**
     * @notice  Initialize the contract
     * @param   _lpToken  The address of the LP token
     */
    function initializeLp(address _lpToken) external {
        if (lpToken != address(0)) revert CannotInitialize();

        lpToken = _lpToken;
        factory = msg.sender;

        string memory _symbol = IERC20Metadata(_lpToken).symbol();
        string memory _name = string.concat("Opal ", _symbol, " Gauge Deposit");
        name = _name;
        symbol = string.concat(_symbol, "-Gauge");

        integrateInvSupply.push(0);
        integrateInvSupplyBoosted.push(0);
        periodTimestamp.push(block.timestamp);
        inflationRate = IMinter(MINTER).rate();
        inflationRateBoosted = IMinterEscrow(MINTER_ESCROW).rate();
        futureEpochTime = IMinter(MINTER).futureEpochTimeWrite();
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyOpalTeam {}

    // View functions

    /**
     * @notice  Get the decimals of the token
     * @return  uint256
     */
    function decimals() external pure returns (uint256) {
        return 18;
    }

    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view virtual returns (bytes32) {
        return _domainSeparator();
    }

    /**
     * @notice  Integrate checkpoint
     * @return  uint256  .
     */
    function integrateCheckpoint() external view returns (uint256) {
        return periodTimestamp[period];
    }

    // State-changing functions

    /**
     * @notice  Checkpoint user
     * @param   user  The address of the user
     * @return  bool  .
     */
    function userCheckpoint(address user) external returns (bool) {
        if (msg.sender != user && msg.sender != MINTER && msg.sender != MINTER_ESCROW) {
            revert CallerNotAllowed();
        }
        _checkpoint(user);
        _updateLiquidityLimit(user, balanceOf[user], totalSupply);
        return true;
    }

    /**
     * @notice  Claimable tokens
     * @param   user  The address of the user
     * @return  uint256  .
     */
    function claimableTokens(address user) external returns (uint256) {
        _checkpoint(user);
        return integrateFraction[user] - IMinter(MINTER).minted(user, address(this));
    }

    /**
     * @notice  Claimable escrow tokens
     * @param   user  The address of the user
     * @return  uint256  .
     */
    function claimableEscrowTokens(address user) external returns (uint256) {
        _checkpoint(user);
        return integrateFractionBoosted[user]
            - IMinterEscrow(MINTER_ESCROW).minted(user, address(this));
    }

    /**
     * @notice  All claimable tokens (bormal and escrowed) for the user
     * @param   user  The address of the user
     * @return  basicAmount  amount of basic tokens
     * @return  escrowAmount  amount of escrowed tokens
     */
    function claimable(address user) external returns (uint256 basicAmount, uint256 escrowAmount) {
        _checkpoint(user);
        basicAmount = integrateFraction[user] - IMinter(MINTER).minted(user, address(this));
        escrowAmount = integrateFractionBoosted[user]
            - IMinterEscrow(MINTER_ESCROW).minted(user, address(this));
    }

    /**
     * @notice  Kick function
     * @param   user  The address of the user
     */
    function kick(address user) external {
        uint256 lastTime = integrateCheckpointOf[user];
        (,,, IVoteLocker.LockedBalance[] memory userLocks) =
            IVoteLocker(VL_TOKEN).lockedBalances(user);
        uint256 vlTime = userLocks[userLocks.length - 1].unlockTime;
        uint256 userBalance = balanceOf[user];

        if (IVoteLocker(VL_TOKEN).balanceOf(user) > 0 && vlTime < lastTime) return;
        if (workingBalances[user] <= (userBalance * TOKENLESS_PRODUCTION / 100)) return;

        _checkpoint(user);
        _updateLiquidityLimit(user, balanceOf[user], totalSupply);
    }

    /**
     * @notice  Deposit function
     * @param   value  The amount of tokens to deposit
     */
    function deposit(uint256 value) external nonReentrant {
        _deposit(value, msg.sender);
    }

    /**
     * @notice  Deposit function
     * @param   value  The amount of tokens to deposit
     * @param   user  The address of the user
     */
    function deposit(uint256 value, address user) external nonReentrant {
        _deposit(value, user);
    }

    /**
     * @notice  Withdraw function
     * @param   value  The amount of tokens to withdraw
     */
    function withdraw(uint256 value) external nonReentrant {
        _withdraw(value);
    }

    /**
     * @notice  Withdraw function
     * @param   to  The address of the user
     * @param   value  The amount of tokens to withdraw
     * @return  bool  .
     */
    function transfer(address to, uint256 value) external nonReentrant returns (bool) {
        _transfer(msg.sender, to, value);
        return true;
    }

    /**
     * @notice  TransferFrom function
     * @param   from  The address of the user
     * @param   to  The address of the user
     * @param   value  The amount of tokens to transfer
     * @return  bool  .
     */
    function transferFrom(address from, address to, uint256 value)
        external
        nonReentrant
        returns (bool)
    {
        uint256 _allowance = allowance[from][msg.sender];
        if (_allowance != MAX_UINT256) {
            allowance[from][msg.sender] = _allowance - value;
        }

        _transfer(from, to, value);
        return true;
    }

    /**
     * @notice  Approve function
     * @param   spender  The address of the spender
     * @param   value  The amount of tokens to approve
     * @return  bool  .
     */
    function approve(address spender, uint256 value) external nonReentrant returns (bool) {
        allowance[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

    /**
     * @notice  Permit function
     * @param   owner  address of the owner
     * @param   spender  address of the spender
     * @param   value  amount of tokens
     * @param   deadline  timestamp where signature not valid
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual {
        if (owner == address(0)) revert AddressZero();
        if (block.timestamp > deadline) revert SignatureExpired();

        uint256 userNonce = nonces[owner];
        bytes32 structHash =
            keccak256(abi.encode(PERMIT_TYPEHASH, owner, spender, value, userNonce, deadline));

        bytes32 _hash = MessageHashUtils.toTypedDataHash(_domainSeparator(), structHash);

        address signer = ECDSA.recover(_hash, v, r, s);
        if (signer != owner) revert SignatureInvalid();

        allowance[owner][spender] = value;
        nonces[owner]++;
    }

    // Internal functions

    /**
     * @notice  Deposit function
     * @param   value  The amount of tokens to deposit
     * @param   user  The address of the user
     */
    function _deposit(uint256 value, address user) internal {
        _checkpoint(user);

        if (value > 0) {
            uint256 _totalSupply = totalSupply;
            _totalSupply += value;
            uint256 newUserBalance = balanceOf[user] + value;
            balanceOf[user] = newUserBalance;
            totalSupply = _totalSupply;

            _updateLiquidityLimit(user, newUserBalance, _totalSupply);

            IERC20(lpToken).safeTransferFrom(msg.sender, address(this), value);
        }

        emit Deposit(user, value);
        emit Transfer(address(0), user, value);
    }

    /**
     * @notice  Withdraw function
     * @param   value  The amount of tokens to withdraw
     */
    function _withdraw(uint256 value) internal {
        _checkpoint(msg.sender);

        if (value > 0) {
            uint256 _totalSupply = totalSupply;
            _totalSupply -= value;
            uint256 newUserBalance = balanceOf[msg.sender] - value;
            balanceOf[msg.sender] = newUserBalance;
            totalSupply = _totalSupply;

            _updateLiquidityLimit(msg.sender, newUserBalance, _totalSupply);

            IERC20(lpToken).safeTransfer(msg.sender, value);
        }

        emit Withdraw(msg.sender, value);
        emit Transfer(msg.sender, address(0), value);
    }

    /**
     * @notice  Transfer function
     * @param   from  address of the sender
     * @param   to  address of the receiver
     * @param   value  amount of tokens
     */
    function _transfer(address from, address to, uint256 value) internal {
        _checkpoint(from);
        _checkpoint(to);

        if (value > 0) {
            uint256 _totalSupply = totalSupply;

            uint256 newFromBalance = balanceOf[from] - value;
            balanceOf[from] = newFromBalance;
            _updateLiquidityLimit(from, newFromBalance, _totalSupply);

            uint256 newToBalance = balanceOf[to] + value;
            balanceOf[to] = newToBalance;
            _updateLiquidityLimit(to, newToBalance, _totalSupply);
        }

        emit Transfer(from, to, value);
    }

    /**
     * @notice  Update liquidity limit
     * @param   user  The address of the user
     * @param   l  limit of the user
     * @param   L  total limit
     */
    function _updateLiquidityLimit(address user, uint256 l, uint256 L) internal {
        uint256 userBalance = IVoteLocker(VL_TOKEN).balanceOf(user);
        uint256 totalLockedSupply = IVoteLocker(VL_TOKEN).totalSupply();
        uint256 lim = (l * TOKENLESS_PRODUCTION) / 100;
        if (totalLockedSupply > 0) {
            lim += L * userBalance / totalLockedSupply * (100 - TOKENLESS_PRODUCTION) / 100;
        }
        if (lim > l) lim = l;

        uint256 oldBalance = workingBalances[user];
        workingBalances[user] = lim;
        uint256 _workingSupply = workingSupply - oldBalance + lim;
        workingSupply = _workingSupply;

        emit UpdateLiquidityLimit(user, l, L, lim, _workingSupply);
    }

    /**
     * @notice  Checkpoint function
     * @param   user  The address of the user
     */
    function _checkpoint(address user) internal {
        uint256 _period = period;
        uint256 periodTime = periodTimestamp[_period];

        uint256 _integrateInvSupply = integrateInvSupply[_period];
        uint256 _integrateInvSupplyBoosted = integrateInvSupplyBoosted[_period];

        uint256 rate = inflationRate;
        uint256 newRate = rate;
        uint256 prevFutureEpoch = futureEpochTime;
        if (prevFutureEpoch >= periodTime) {
            futureEpochTime = IMinter(MINTER).futureEpochTimeWrite();
            newRate = IMinter(MINTER).rate();
            inflationRate = newRate;
        }
        uint256 rateBoosted = inflationRateBoosted;
        uint256 newRateBoosted = IMinterEscrow(MINTER_ESCROW).rate();
        uint256 endTimestamp;
        if (newRateBoosted != rateBoosted) {
            endTimestamp = IMinterEscrow(MINTER_ESCROW).distributionEnd();
            inflationRateBoosted = newRateBoosted;
        }

        if (isKilled) {
            rate = 0;
        }

        if (block.timestamp > periodTime) {
            uint256 _workingSupply = workingSupply;
            uint256 _totalSupply = totalSupply;

            IGaugeController(GAUGE_CONTROLLER).checkpointGauge(address(this));

            uint256 prevWeekTime = periodTime;
            uint256 weekTime = (periodTime + WEEK) / WEEK * WEEK;
            if (weekTime > block.timestamp) weekTime = block.timestamp;

            for (uint256 i; i < 500; i++) {
                uint256 dt = weekTime - prevWeekTime;
                uint256 w = IGaugeController(GAUGE_CONTROLLER).gaugeRelativeWeight(
                    address(this), prevWeekTime / WEEK * WEEK
                );
                if (_totalSupply > 0) {
                    if (prevFutureEpoch >= prevWeekTime && prevFutureEpoch < weekTime) {
                        _integrateInvSupply +=
                            rate * w * (prevFutureEpoch - prevWeekTime) / _totalSupply;
                        rate = newRate;
                        _integrateInvSupply +=
                            rate * w * (weekTime - prevFutureEpoch) / _totalSupply;
                    } else {
                        _integrateInvSupply += rate * w * dt / _totalSupply;
                    }
                }

                if (_workingSupply > 0 && rateBoosted > 0) {
                    if (
                        endTimestamp >= prevWeekTime && endTimestamp < weekTime && endTimestamp != 0
                    ) {
                        _integrateInvSupplyBoosted +=
                            rateBoosted * w * (endTimestamp - prevWeekTime) / _workingSupply;
                        rateBoosted = newRate;
                    } else {
                        _integrateInvSupplyBoosted += rateBoosted * w * dt / _workingSupply;
                    }
                }

                if (weekTime == block.timestamp) break;

                prevWeekTime = weekTime;
                weekTime = weekTime + WEEK > block.timestamp ? block.timestamp : weekTime + WEEK;
            }
        }

        _period++;
        period = _period;
        periodTimestamp.push(block.timestamp);
        integrateInvSupply.push(_integrateInvSupply);
        integrateInvSupplyBoosted.push(_integrateInvSupplyBoosted);

        uint256 _userBalance = balanceOf[user];
        integrateFraction[user] +=
            _userBalance * (_integrateInvSupply - integrateInvSupplyOf[user]) / 10 ** 18;
        integrateInvSupplyOf[user] = _integrateInvSupply;
        integrateCheckpointOf[user] = block.timestamp;

        uint256 _workingBalance = workingBalances[user];
        integrateFractionBoosted[user] += _workingBalance
            * (_integrateInvSupplyBoosted - integrateBoostedInvSupplyOf[user]) / 10 ** 18;
        integrateBoostedInvSupplyOf[user] = _integrateInvSupplyBoosted;
        integrateBoostedCheckpointOf[user] = block.timestamp;
    }

    function _domainSeparator() internal view returns (bytes32) {
        return keccak256(abi.encode(EIP712_TYPEHASH, name, VERSION, block.chainid, address(this)));
    }

    // Admin functions

    /**
     * @notice  Kill the contract
     * @param   _isKilled  .
     */
    function setKilled(bool _isKilled) external onlyOpalTeam {
        isKilled = _isKilled;
    }
}
