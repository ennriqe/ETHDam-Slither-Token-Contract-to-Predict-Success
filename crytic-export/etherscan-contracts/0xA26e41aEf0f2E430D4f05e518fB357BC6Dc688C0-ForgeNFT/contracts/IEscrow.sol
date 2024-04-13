pragma solidity ^0.8.20;

interface IEscrow { 
    struct NftReserve {
        uint256 publicReserved;
        uint256 coFounderReserved;
        uint256 price;
    }

    function nftReserveAmount(address) external view returns (NftReserve memory);

    function claimFor(address _account) external;
}
