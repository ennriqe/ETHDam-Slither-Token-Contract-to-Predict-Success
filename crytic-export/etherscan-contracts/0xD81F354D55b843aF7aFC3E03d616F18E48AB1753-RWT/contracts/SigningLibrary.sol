// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;


/**
 * @title Signing Library
 * @author Monkhub Innovations
 * @notice A signature library to use for signature generation and verification, using basic and versatile parameters
 */
library SigningLibrary {

    
    function getMessageHash(
        address target,
        address target2,
        uint256 amount,
        uint8 functionType,
        bytes32 instanceIdentifier,
        uint256 chainId
    ) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(target, target2, amount, functionType, instanceIdentifier, chainId));
    }




    /**
     * @dev Generates signing format for messageHash
     * @param _messageHash messageHash from getMessageHash
     */
    function getEthSignedMessageHash(
        bytes32 _messageHash
    ) public pure returns (bytes32) {
        /*
        Signature is produced by signing a keccak256 hash with the following format:
        "\x19Ethereum Signed Message\n" + len(msg) + msg
        */
        return
            keccak256(
                abi.encodePacked(
                    "\x19Ethereum Signed Message:\n32",
                    _messageHash
                )
            );
    }

    
    function verify(
        address _signer,
        address target,
        address target2,
        uint256 amount,
        uint8 functionType,
        bytes32 instanceIdentifier,
        uint256 chainId,
        bytes memory signature
    ) public pure returns (bool) {
        bytes32 messageHash = getMessageHash(
            target, target2, amount, functionType, instanceIdentifier, chainId
        );
        bytes32 ethSignedMessageHash = getEthSignedMessageHash(messageHash);
        return recoverSigner(ethSignedMessageHash, signature) == _signer;
    }

    // recoverSigner and splitSignature functions remain unchanged



/**
 * @dev recovers signer from signature using signedMessageHash structure
 */
    function recoverSigner(
        bytes32 _ethSignedMessageHash,
        bytes memory _signature
    ) public pure returns (address) {
        (bytes32 r, bytes32 s, uint8 v) = splitSignature(_signature);

        return ecrecover(_ethSignedMessageHash, v, r, s);
    }

/**
 * @dev splits signature into components
 */
    function splitSignature(
        bytes memory sig
    ) public pure returns (bytes32 r, bytes32 s, uint8 v) {
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
}
