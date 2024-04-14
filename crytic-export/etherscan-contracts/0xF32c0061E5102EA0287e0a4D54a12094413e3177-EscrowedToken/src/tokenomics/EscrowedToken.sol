// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {ERC20Upgradeable} from
    "@openzeppelin-upgradeable-contracts/token/ERC20/ERC20Upgradeable.sol";
import {UUPSUpgradeable} from "@openzeppelin-upgradeable-contracts/proxy/utils/UUPSUpgradeable.sol";
import {Initializable} from "@openzeppelin-upgradeable-contracts/proxy/utils/Initializable.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

import {IRegistryAccess} from "src/interfaces/Registry/IRegistryAccess.sol";
import {IRegistryContract} from "src/interfaces/Registry/IRegistryContract.sol";

import {
    CONTRACT_REGISTRY_ACCESS,
    ROLE_MINT_ESCROW_TOKEN,
    ROLE_OPAL_TEAM,
    SCALED_ONE,
    WEEK
} from "src/utils/constants.sol";

contract EscrowedToken is Initializable, UUPSUpgradeable, ERC20Upgradeable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    // Structs

    /**
     * @notice UserVesting struct
     *   index: index of the vesting in the user list
     *   amount: amount being vested
     *   ratePerToken: ratePerToken at creation time
     *   end: vesting end timestamp
     *   claimed: vesting was claimed
     */
    struct UserVesting {
        uint256 index;
        uint256 amount;
        uint200 ratePerToken;
        uint48 end;
        bool claimed;
    }

    // Storage

    IERC20 public token;
    IRegistryContract public registryContract;
    IRegistryAccess public registryAccess;

    uint256 public totalVesting;
    uint256 public ratePerToken = SCALED_ONE;

    uint256 public vestingDuration = WEEK * 8;

    mapping(address => UserVesting[]) public vestings;
    mapping(address => uint256) public userVestingCount;

    uint256 public unclaimableSupply;

    // Errors

    error CannotTransfer();
    error ZeroAddress();
    error ZeroValue();
    error InvalidIndex(uint256 index);
    error EmptyArray();
    error InvalidTimestamp();
    error VestingAlreadyClaimed(uint256 index);
    error NumberExceed200Bits();
    error NumberExceed48Bits();
    error NotAuthorized();

    // Events

    event VestingStarted(address indexed owner, uint256 amount, uint256 end);
    event VestingClaimed(address indexed owner, uint256 amount);
    event UnclaimableSupplyRetrieved(uint256 amount);

    // Constructor

    modifier onlyMinterRole() {
        if (!registryAccess.checkRole(ROLE_MINT_ESCROW_TOKEN, msg.sender)) revert NotAuthorized();
        _;
    }

    modifier onlyOpalTeam() {
        if (!registryAccess.checkRole(ROLE_OPAL_TEAM, msg.sender)) revert NotAuthorized();
        _;
    }

    constructor() {
        _disableInitializers();
    }

    function initialize(
        address _token,
        string memory _name,
        string memory _symbol,
        address _registryContract
    ) public initializer {
        if (_token == address(0)) revert ZeroAddress();
        __UUPSUpgradeable_init_unchained();
        __ERC20_init_unchained(_name, _symbol);

        token = IERC20(_token);
        registryContract = IRegistryContract(_registryContract);
        registryAccess = IRegistryAccess(registryContract.getContract(CONTRACT_REGISTRY_ACCESS));
    }

    // Overrides

    function _authorizeUpgrade(address) internal override onlyOpalTeam {}

    /**
     * @notice  Transfer method
     * @dev     This method is overriden to prevent transfers
     * @return  bool  .
     */
    // solhint-disable-next-line
    function transfer(address, /*to*/ uint256 /*amount*/ )
        public
        pure
        override(ERC20Upgradeable)
        returns (bool)
    {
        revert CannotTransfer();
    }

    /**
     * @notice  Transfer method
     * @dev     This method is overriden to prevent transfers
     * @return  bool  .
     */
    // solhint-disable-next-line
    function transferFrom(address, /*from*/ address, /*to*/ uint256 /*amount*/ )
        public
        pure
        override(ERC20Upgradeable)
        returns (bool)
    {
        revert CannotTransfer();
    }

    // View methods

    /**
     * @notice  Get user vestings
     * @param   user  The address of the user
     * @return  UserVesting[]  .
     */
    function getUserVestings(address user) external view returns (UserVesting[] memory) {
        return vestings[user];
    }

    /**
     * @notice  Get user active vestings
     * @param   user  The address of the user
     * @return  UserVesting[]  .
     */
    function getUserActiveVestings(address user) external view returns (UserVesting[] memory) {
        uint256 activeCount;
        uint256 userCount = userVestingCount[user];
        for (uint256 i; i < userCount;) {
            if (!vestings[user][i].claimed) {
                activeCount++;
            }
            unchecked {
                ++i;
            }
        }

        uint256 index;
        UserVesting[] memory activeVestings = new UserVesting[](activeCount);
        for (uint256 i; i < userCount;) {
            if (!vestings[user][i].claimed) {
                activeVestings[index] = vestings[user][i];
                unchecked {
                    ++index;
                }
            }
            unchecked {
                ++i;
            }
        }

        return activeVestings;
    }

    /**
     * @notice  Get the vesting claim value
     * @param   user  The address of the user
     * @param   index The index of the vesting
     * @return  currentValue  .
     * @return  maxValue  .
     */
    function getVestingClaimValue(address user, uint256 index)
        external
        view
        returns (uint256 currentValue, uint256 maxValue)
    {
        if (index >= userVestingCount[user]) revert InvalidIndex(index);
        UserVesting storage userVesting = vestings[user][index];
        if (userVesting.claimed) return (0, 0);

        uint256 remainingTime;
        if (block.timestamp < userVesting.end) {
            remainingTime = userVesting.end - block.timestamp;
        }

        uint256 claimAmount = (
            userVesting.amount * (SCALED_ONE + (ratePerToken - userVesting.ratePerToken))
        ) / SCALED_ONE;
        maxValue = claimAmount;

        uint256 removedAmount = (claimAmount * remainingTime) / vestingDuration + 1;
        claimAmount -= removedAmount > claimAmount ? claimAmount : removedAmount;

        currentValue = claimAmount;
    }

    // State changing functions

    /**
     * @notice  Mint method
     * @param   amount  .
     * @param   receiver  .
     * @param   startTimestamp  Begin timestamp
     */
    function mint(uint256 amount, address receiver, uint256 startTimestamp)
        external
        nonReentrant
        onlyMinterRole
    {
        if (amount == 0) revert ZeroValue();
        if (receiver == address(0)) revert ZeroAddress();
        if (startTimestamp < block.timestamp) revert InvalidTimestamp();
        token.safeTransferFrom(msg.sender, address(this), amount);

        uint256 vestingEnd = startTimestamp + vestingDuration;

        vestings[receiver].push(
            UserVesting({
                index: userVestingCount[receiver],
                amount: amount,
                ratePerToken: safe200(ratePerToken),
                end: safe48(vestingEnd),
                claimed: false
            })
        );
        userVestingCount[receiver]++;

        totalVesting += amount;

        emit VestingStarted(receiver, amount, vestingEnd);

        _mint(receiver, amount);
    }

    /**
     * @notice  Claim method
     * @param   vestingIndex  Vesting index
     */
    function claim(uint256 vestingIndex) external nonReentrant {
        _claim(msg.sender, vestingIndex);
    }

    /**
     * @notice  Claim multiple vestings
     * @param   vestingIndex  Vesting index
     */
    function claimMultiple(uint256[] calldata vestingIndex) external nonReentrant {
        uint256 length = vestingIndex.length;
        if (length == 0) revert EmptyArray();
        for (uint256 i; i < length;) {
            _claim(msg.sender, vestingIndex[i]);
            unchecked {
                i++;
            }
        }
    }

    /**
     * @notice  Claim all vestings
     */
    function claimAll() external nonReentrant {
        uint256 userNextIndex = userVestingCount[msg.sender];
        for (uint256 i; i < userNextIndex; i++) {
            if (vestings[msg.sender][i].claimed) continue;
            _claim(msg.sender, i);
        }
    }

    // Internal functions

    /**
     * @notice  Claim method
     * @param   account address of the account
     * @param   vestingIndex  Vesting index
     */
    function _claim(address account, uint256 vestingIndex) internal {
        if (vestingIndex >= userVestingCount[account]) revert InvalidIndex(vestingIndex);
        UserVesting storage userVesting = vestings[account][vestingIndex];
        if (userVesting.claimed) revert VestingAlreadyClaimed(vestingIndex);

        uint256 remainingTime;
        if (block.timestamp < userVesting.end) {
            remainingTime = userVesting.end - block.timestamp;
        }

        uint256 claimAmount = (
            userVesting.amount * (SCALED_ONE + (ratePerToken - userVesting.ratePerToken))
        ) / SCALED_ONE;
        uint256 removedAmount = (claimAmount * remainingTime) / vestingDuration + 1;
        claimAmount -= removedAmount > claimAmount ? claimAmount : removedAmount;

        userVesting.claimed = true;
        totalVesting -= userVesting.amount;
        _burn(account, userVesting.amount);

        token.safeTransfer(account, claimAmount);
        if (totalVesting > 0) {
            ratePerToken += (SCALED_ONE * removedAmount) / totalVesting;
        } else {
            unclaimableSupply += removedAmount;
        }

        emit VestingClaimed(account, claimAmount);
    }

    // Admin functions

    /**
     * @notice Retrieve stuck unclaimed funds
     * @param receiver Address to receive the funds
     */
    function retrieveUnclaimedSupply(address receiver) external onlyOpalTeam {
        if (receiver == address(0)) revert ZeroAddress();

        uint256 amount = unclaimableSupply;
        unclaimableSupply = 0;
        token.transfer(receiver, amount);

        emit UnclaimableSupplyRetrieved(amount);
    }

    // Maths
    function safe200(uint256 n) internal pure returns (uint200) {
        if (n > type(uint200).max) revert NumberExceed200Bits();
        return uint200(n);
    }

    function safe48(uint256 n) internal pure returns (uint48) {
        if (n > type(uint48).max) revert NumberExceed48Bits();
        return uint48(n);
    }
}
