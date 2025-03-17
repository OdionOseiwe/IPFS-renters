// contracts/interfaces/IStorageMarket.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface IStorageMarket {
    struct StorageAgreement {
        address user;
        address provider;
        string fileReference; // IPFS CID
        uint256 size;
        uint256 duration;
        uint256 price;
        uint256 startTime;
        bool active;
    }
    
    event AgreementCreated(uint256 indexed agreementId, address indexed user, address indexed provider);
    event FileStored(uint256 indexed agreementId, string fileReference);
    event AgreementTerminated(uint256 indexed agreementId);
    event AgreementExtended(uint256 agreementId, uint256 additionalMonths, uint256 amount);
    event AgreementRenewed(uint256 agreementId, uint256 amount);

    function createStorageAgreement(address provider, uint256 size, uint256 duration, uint256 amount) external  returns (uint256);
    function storeFile(uint256 agreementId, string calldata fileReference) external;
    function terminateAgreement(uint256 agreementId) external;
    function getAgreement(uint256 agreementId) external view returns (StorageAgreement memory);
}
