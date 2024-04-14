// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.20;

interface ICoreSignatureVerificationV1 {
    event SignatureVerificationSignerUpdate(address signer, address updatedBy);

    function setSignatureVerificationSigner(address signer) external;
}
