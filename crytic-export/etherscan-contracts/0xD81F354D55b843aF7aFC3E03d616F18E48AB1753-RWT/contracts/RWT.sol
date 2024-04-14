// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "./SigningLibrary.sol";

/**
 * @title RockWallet Stablecoin Implementation v1
 * @author Monkhub Innovations
 * @notice Relies on SigningLibrary for signature facilities
 * @dev utilizes ERC20, is a MinterPauserBurner, with significant authority of oeprations lying with authorized validators
 */
contract RWT is Initializable, ERC20Upgradeable, PausableUpgradeable {
    address public redeemer;
    uint8 public constant requiredSignatures = 3;
    uint8 public constant roleHolders = 4;
    address public admin;
    address public rescuer;
    mapping(address => bool) public blacklisted;
    mapping(address => bool) public frozen;
    mapping(bytes32 => bool) public instanceNonces;
    mapping(address => bool) public isMinter;
    mapping(address => bool) public isBurner;
    mapping(address => bool) public isPauser;
    mapping(address => bool) public isBlacklisterFreezer;

    enum validatorRole {
        minter,
        burner,
        pauser,
        blacklister_freezer
    }

    enum functionType {
        mint,
        burn,
        burnHoldings,
        freeze,
        blacklist,
        delist,
        unfreeze,
        confiscate,
        pause,
        unpause,
        changeMinter,
        changeBurner,
        changePauser,
        changeBlacklisterFreezer
    }

    event TokensMinted(address indexed account, uint256 indexed amount);
    event TokensBurnt(uint256 indexed amount);
    event HoldingsBurnt(address indexed account, uint256 indexed amount);
    event AccountFrozen(address indexed account);
    event AccountUnfrozen(address indexed account);
    event AccountBlacklisted(address indexed account);
    event AccountDelisted(address indexed account);
    event FundsConfiscated(
        address indexed account,
        uint256 indexed amount,
        address indexed sentTo
    );
    event FundsRescued(
        address indexed token,
        uint256 indexed amount,
        address indexed sentTo
    );
    event ChangeMinter(address indexed old, address indexed _new);
    event ChangeBurner(address indexed old, address indexed _new);
    event ChangePauser(address indexed old, address indexed _new);
    event ChangeBlacklisterFreezer(address indexed old, address indexed _new);
    event ChangeRedeemer(address indexed _new);
    event ChangeRescuer(address indexed _new);

    error zeroAddress();
    error notZeroAddress();
    error onlyAdmin();
    error onlyCorrectValidator();
    error invalidSigner();
    error invalidSign();
    error neitherBLnorF();
    error blacklistedAddress();
    error frozenAddress();
    error BLorF();
    error notBL();
    error notF();
    error tokenPaused();
    error invalidAmt();
    error wrongFunction();

    /**
     * @dev initializes the implementation, sets all roles initially, gives admin all role qualifications exceot rescuer and redeemer
     * @param _redeemer initial redeemer address, which is target of token burning for redemption requests
     * @param _admin admin address
     * @param _rescuer initial rescuer address
     * @param _minters initial minter validator addresses
     * @param _burners initial minter validator addresses
     * @param _pausers initial minter validator addresses
     * @param _blacklisters_freezers initial minter validator addresses
    */
    function initialize(
        address _redeemer,
        address _admin,
        address _rescuer,
        address[roleHolders] calldata _minters,
        address[roleHolders] calldata _burners,
        address[roleHolders] calldata _pausers,
        address[roleHolders] calldata _blacklisters_freezers
    ) public initializer {
        if (
            _redeemer == address(0) ||
            _rescuer == address(0) ||
            _admin == address(0)
        ) revert zeroAddress();
        redeemer = _redeemer; //target of burning for redemption function
        admin = _admin;
        rescuer = _rescuer;
        __ERC20_init("RockWallet Token", "RWT");
        isMinter[_admin] = true;
        isBurner[_admin] = true;
        isPauser[_admin] = true;
        isBlacklisterFreezer[_admin] = true;
        emit ChangeMinter(address(0), _admin);
        emit ChangeBurner(address(0), _admin);
        emit ChangePauser(address(0), _admin);
        emit ChangeBlacklisterFreezer(address(0), _admin);
        uint96 i = 0;
        for (i = 0; i < _minters.length; i++) {
            isMinter[_minters[i]] = true;
            isBurner[_burners[i]] = true;
            isPauser[_pausers[i]] = true;
            isBlacklisterFreezer[_blacklisters_freezers[i]] = true;

            emit ChangeMinter(address(0), _minters[i]);
            emit ChangeBurner(address(0), _burners[i]);
            emit ChangePauser(address(0), _pausers[i]);
            emit ChangeBlacklisterFreezer(
                address(0),
                _blacklisters_freezers[i]
            );
        }
    }

    /**
     * @dev function to replace redeemer address
     * @notice USE WITH CAUTION! any address can be set to redeemer
     * @param _newRedeemer new redeemer address
     */
    function changeRedeemer(address _newRedeemer) external {
        if (_newRedeemer == address(0)) revert zeroAddress();
        if (_msgSender() != admin) revert onlyAdmin();
        redeemer = _newRedeemer;
        emit ChangeRedeemer(_newRedeemer);
        
    }

    /**
     * @dev function to replace rescuer address
     * @param _newrescuer new rescuer address
     */
    function changeRescuer(address _newrescuer) external {
        if (_newrescuer == address(0)) revert zeroAddress();
        if (_msgSender() != admin) revert onlyAdmin();
        rescuer = _newrescuer;
        emit ChangeRescuer(_newrescuer);
        
    }

    /**
     * @dev function for a particular validator role's addresses to vote and replace an existing validator of the same role
     * @param _old old validator address to be replaced
     * @param _new new validator address to replace the old one
     * @param fType change'Role' function code
     * @param signers signer addresses passed of the particular role
     * @param signatures signatures approving this change
     */
    function replaceValidator(
    address _old,
    address _new,
    functionType fType,
    address[requiredSignatures] calldata signers,
    bytes32 instanceIdentifier,
    bytes[requiredSignatures] calldata signatures
)
 external{
    require(signers[0] != signers[2], "Signers must be unique");
    require(!instanceNonces[instanceIdentifier], "Invalid uuid");
    instanceNonces[instanceIdentifier] = true;
        for (uint8 i = 0; i < requiredSignatures; i++) {
        // Ensure the nonce is correct and the signature is valid
        if (fType == functionType.changeMinter) {
               if (!(isMinter[signers[i]])) revert invalidSigner();
           } else if (fType == functionType.changeBurner) {
               if (!(isBurner[signers[i]])) revert invalidSigner();
           } else if (fType == functionType.changePauser) {
               if (!(isPauser[signers[i]])) revert invalidSigner();
           } else if (fType == functionType.changeBlacklisterFreezer) {
               if (!(isBlacklisterFreezer[signers[i]])) revert invalidSigner();
           }


           if(i >0)
               if(signers[i] == signers[i-1]) revert invalidSigner();
        if (
                !SigningLibrary.verify(
                    signers[i],
                    _old,
                    _new,
                    0,
                    uint8(fType),
                    instanceIdentifier,
                    block.chainid,
                    signatures[i]
                )
            ) revert invalidSign();

    }


        if (fType == functionType.changeMinter) {
            if (!isMinter[_msgSender()]) revert onlyCorrectValidator();
            isMinter[_old] = false;
            isMinter[_new] = true;
            emit ChangeMinter(_old, _new);
        } else if (fType == functionType.changeBurner) {
            if (!isBurner[_msgSender()]) revert onlyCorrectValidator();
            isBurner[_old] = false;
            isBurner[_new] = true;
            emit ChangeBurner(_old, _new);
        } else if (fType == functionType.changePauser) {
            if (!isPauser[_msgSender()]) revert onlyCorrectValidator();
            isPauser[_old] = false;
            isPauser[_new] = true;
            emit ChangePauser(_old, _new);
        } else if (fType == functionType.changeBlacklisterFreezer) {
            if (!isBlacklisterFreezer[_msgSender()])
                revert onlyCorrectValidator();
            isBlacklisterFreezer[_old] = false;
            isBlacklisterFreezer[_new] = true;
            emit ChangeBlacklisterFreezer(_old, _new);
        } else revert wrongFunction();
    }

    /**
     * @dev function for a using minting, burning, pausing and unpausing. requires 3 valid signs from 3 valid signers
     * @param _target target address required for minting or burning. inconsequential in case of pausing/unpausing
     * @param _amount amount required for minting or burning. inconsequential in case of pausing/unpausing
     * @param fType function code to be carried out
     * @param signers signer addresses passed of the particular role
     * @param signatures signatures approving this change
     */
    function mintBurnPauseUnpause(
    address _target,
    uint256 _amount,
    functionType fType,
    address[requiredSignatures] calldata signers,
    bytes[requiredSignatures] calldata signatures,
    bytes32 instanceIdentifier
)
 external {
    require(signers[0] != signers[2], "Signers must be unique");
    require(!instanceNonces[instanceIdentifier], "Invalid uuid");
    instanceNonces[instanceIdentifier] = true;
    for (uint8 i = 0; i < requiredSignatures; i++) {
            if (fType == functionType.mint) {
               if (!(isMinter[signers[i]])) revert invalidSigner();
           } else if (fType == functionType.burn) {
               if (!(isBurner[signers[i]])) revert invalidSigner();
           } else if (
               fType == functionType.pause || fType == functionType.unpause
           ) {
               if (!(isPauser[signers[i]])) revert invalidSigner();
           }


           if(i >0)
               if(signers[i] == signers[i-1]) revert invalidSigner();
        if (
                !SigningLibrary.verify(
                    signers[i],
                    _target,
                    address(0),
                    _amount,
                    uint8(fType),
                    instanceIdentifier,
                    block.chainid,
                    signatures[i]
                )
            ) revert invalidSign();
    }
        if (fType == functionType.mint) {
            if (!isMinter[_msgSender()]) revert onlyCorrectValidator();
            _mint(_target, _amount);
            emit TokensMinted(_target, _amount);
        } else if (fType == functionType.burn) {
            if (!isBurner[_msgSender()]) revert onlyCorrectValidator();
            super._burn(redeemer, _amount);
            emit TokensBurnt(_amount);
        } else if (
            fType == functionType.pause || fType == functionType.unpause
        ) {
            if (!isPauser[_msgSender()]) revert onlyCorrectValidator();
            if (fType == functionType.pause) super._pause();
            else if (fType == functionType.unpause) super._unpause();
        }
        else revert wrongFunction();

        

    }

    /**
     * @dev function for a using blacklisting, delisting, freezing, unfreezing, confiscation and holdings burning. requires 3 valid signs from 3 valid signers
     * @param _address address target for blacklisting, delisting, freezing, unfreezing, confiscation and holdings burning
     * @param _to address recepient in case of confiscation
     * @param _amount amount required for confiscation or burning holding. inconsequential in case of blacklisting-delisting or freezing-unfreezing
     * @param fType function code to be carried out
     * @param signers signer addresses passed of the particular role
     * @param signatures signatures approving this change
     */
   function blacklisterFreezerOps(
    address _address,
    address _to,
    functionType fType,
    uint256 _amount,
    address[requiredSignatures] calldata signers,
    bytes[requiredSignatures] calldata signatures,
    bytes32 instanceIdentifier
)
 external {
        require(signers[0] != signers[2], "Signers must be unique");
        require(!instanceNonces[instanceIdentifier], "Invalid uuid");
        instanceNonces[instanceIdentifier] = true;
        if (!isBlacklisterFreezer[_msgSender()]) revert onlyCorrectValidator();
        for (uint8 i = 0; i < requiredSignatures; i++) {
            if (!(isBlacklisterFreezer[signers[i]])) revert invalidSigner();


           if(i >0)
               if(signers[i] == signers[i-1]) revert invalidSigner();
        if (
                !SigningLibrary.verify(
                    signers[i],
                    _address,
                    _to,
                    _amount,
                    uint8(fType),
                    instanceIdentifier,
                    block.chainid,
                    signatures[i]
                )
            ) revert invalidSign();
    }


        if (fType == functionType.burnHoldings) {
            if (!(blacklisted[_address] || frozen[_address]))
                revert neitherBLnorF();
            if (_to != address(0)) revert notZeroAddress();
            super._burn(_address, _amount);
            emit HoldingsBurnt(_address, _amount);
        } else if (fType == functionType.confiscate) {
            if (!(blacklisted[_address] || frozen[_address]))
                revert neitherBLnorF();
            if (_to == address(0)) revert zeroAddress();
            _transfer(_address, _to, _amount);
            emit FundsConfiscated(_address, _amount, _to);
        } else if (fType == functionType.blacklist) {
            if ((blacklisted[_address]) || (frozen[_address])) revert BLorF();
            blacklisted[_address] = true;
            emit AccountBlacklisted(_address);
        } else if (fType == functionType.freeze) {
            if ((blacklisted[_address]) || (frozen[_address])) revert BLorF();
            frozen[_address] = true;
            emit AccountFrozen(_address);
        } else if (fType == functionType.unfreeze) {
            if (!frozen[_address]) revert notF();
            frozen[_address] = false;
            emit AccountUnfrozen(_address);
        } else if (fType == functionType.delist) {
            if (!blacklisted[_address]) revert notBL();
            blacklisted[_address] = false;
            emit AccountDelisted(_address);
        } else revert wrongFunction();
    }

    /**
     * @dev Rescue operation to fetch ERC20 tokens stuck in the smart contract
     * @param token ERC20 token address
     * @param _amount amount of tokens to move
     * @param _requester address who requested fetching of their tokens
     */
    function rescue(
        IERC20 token,
        uint256 _amount,
        address _requester
    ) external {
        if (!(rescuer == _msgSender())) revert onlyCorrectValidator();
        if (address(token) == address(0)) revert zeroAddress();
        if (_amount == 0) revert invalidAmt();
        if (_requester == address(0)) revert zeroAddress();
        token.transfer(_requester, _amount);
        emit FundsRescued(address(token), _amount, _requester);
    }

    /**
     * @dev override of standard _beforeTokenTransfer, to restrict blacklisted or frozen accounts but allow their confiscation
     * @notice frozen addresses cannot send tokens, blacklisted addresses can neither accept nor send tokens
     * @param from address to move tokens from
     * @param to address to move tokens to
     * @param amount amount of tokens to move 
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override {
        if (!isBlacklisterFreezer[msg.sender]) {
            if (blacklisted[from]) revert blacklistedAddress();
            if (frozen[from]) revert frozenAddress();
        }
        if (blacklisted[to]) revert blacklistedAddress();
        if (paused()) revert tokenPaused();
        super._beforeTokenTransfer(from, to, amount);
    }
}
