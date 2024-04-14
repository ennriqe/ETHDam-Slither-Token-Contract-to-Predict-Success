// SPDX-License-Identifier: MIT
pragma solidity <0.9.0;

library Roles {

    // DEFAULT_ADMIN_ROLE = grant/revoke roles (brickken)
    //
    // This role operated by brickken can grant/revoke any role in the system. Specifically it
    // can also perform some special actions. Brickken operates through Gnosis Safe multisig for every
    // operation.
    //
    // On the escrow:
    //
    // - change issuer, if issuer wallet gets compromised
    // - change payment token, if issuer desires to change the asset used in the offering
    // - change router, if unexpected circumstances forces us to change Uniswap v3 router
    // - change price and swap manager, if unexpected circumstances forces us to change the contract logic
    // - change treasury address, if brickken wants to change where success fees are sent
    // 
    // On the token:
    //
    // - change issuer, if issuer wallet gets compromised
    // - change payment token, if issuer desires to change the asset used to distribute dividends 
    // - change max supply, if there are extensions in the STO equities amount, this will conflict if max supply has been already minted
    // 
    // On the factory:
    //
    // Brickken is the owner and sole operator of the factory so it has full permissions on it

    bytes32 public constant FACTORY_PAUSER_ROLE = keccak256(abi.encode("FACTORY_PAUSER_ROLE")); // pause / unpause factory (brickken);
    bytes32 public constant FACTORY_ISSUER_ROLE = keccak256(abi.encode("FACTORY_ISSUER_ROLE")); // whitelisted issuers (brickken by default);
    bytes32 public constant FACTORY_WHITELISTER_ROLE = keccak256(abi.encode("FACTORY_WHITELISTER_ROLE")); // can whitelist new issuers (brickken);

    bytes32 public constant ESCROW_WITHDRAW_ROLE = keccak256(abi.encode("ESCROW_WITHDRAW_ROLE")); // who can withdraw / partially withdraw to issuer (issuer);
    bytes32 public constant ESCROW_NEW_OFFERING_ROLE = keccak256(abi.encode("ESCROW_NEW_OFFERING_ROLE")); // starts a new offering (issuer);
    bytes32 public constant ESCROW_ERC20WHITELIST_ROLE = keccak256(abi.encode("ESCROW_ERC20WHITELIST_ROLE")); // add/remove ERC20 from whitelist (brickken, issuer);
    bytes32 public constant ESCROW_OFFCHAIN_REPORTER_ROLE = keccak256(abi.encode("ESCROW_OFFCHAIN_REPORTER_ROLE")); // report offchain tickets (issuer);
    bytes32 public constant ESCROW_OFFERING_FINALIZER_ROLE = keccak256(abi.encode("ESCROW_OFFERING_FINALIZER_ROLE")); // finalize an offering (brickken, issuer);

    bytes32 public constant TOKEN_MINTER_ADMIN_ROLE = keccak256(abi.encode("TOKEN_MINTER_ADMIN_ROLE")); // add/remove minters (issuer);
    bytes32 public constant TOKEN_WHITELIST_ADMIN_ROLE = keccak256(abi.encode("TOKEN_WHITELIST_ADMIN_ROLE")); // change investors whitelist (issuer);
    bytes32 public constant TOKEN_CONFISCATE_ADMIN_ROLE = keccak256(abi.encode("TOKEN_CONFISCATE_ADMIN_ROLE")); // pause / unpause or disable confiscation (brickken);
    
    bytes32 public constant TOKEN_URL_ROLE = keccak256(abi.encode("TOKEN_URL_ROLE")); // change url (brickken,issuer);
    bytes32 public constant TOKEN_MINTER_ROLE = keccak256(abi.encode("TOKEN_MINTER_ROLE")); // mint new tokens (issuer, escrow contract);
    bytes32 public constant TOKEN_WHITELIST_ROLE = keccak256(abi.encode("TOKEN_WHITELIST_ROLE")); // whether the user is whitelisted or not (issuer);
    bytes32 public constant TOKEN_CONFISCATE_EXECUTOR_ROLE = keccak256(abi.encode("TOKEN_CONFISCATE_EXECUTOR_ROLE")); // execute confiscation (brickken);
    bytes32 public constant TOKEN_DIVIDEND_DISTRIBUTOR_ROLE = keccak256(abi.encode("TOKEN_DIVIDEND_DISTRIBUTOR_ROLE")); // distribute dividends (issuer);
}