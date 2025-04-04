// contracts/StorageMarket.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../interfaces/IStorageMarket.sol";
import "../interfaces/IStorageNode.sol";
import "./StorageNode.sol";

contract StorageMarket is IStorageMarket{
    StorageNode public nodeRegistry;
    uint256 public nextAgreementId;
    IERC20 public MockUSDT;
    mapping(uint256 => StorageAgreement) public agreements;
    
    // Track agreements by user and provider
    mapping(address => uint256[]) public userAgreements;
    mapping(address => uint256[]) public providerAgreements;
    
    constructor(address _nodeRegistry, address _MockUSDT) {
        nodeRegistry = StorageNode(_nodeRegistry);
        MockUSDT = IERC20(_MockUSDT);
    }

    /// @notice create a new storage agreement
    /// @param provider - adress of the storage provider
    /// @param size - amount of storage being purchased
    /// @param duration - duration of the agreement in months
    /// @param amount - USDT amount for the agreement
    /// @return agreementId - ID of the created agreement
    function createStorageAgreement(address provider, uint256 size, uint256 duration, uint256 amount) 
        external 
        override 
        returns (uint256) 
    {
        IStorageNode.NodeInfo memory nodeInfo = nodeRegistry.getNodeDetails(provider);
        
        require(nodeInfo.owner == provider, "Provider not registered");
        require(nodeInfo.active, "Provider not active");
        require(nodeInfo.availableSpace >= size, "Provider has insufficient space");
        
        uint256 price = size * nodeInfo.pricePerGB * duration;
        require(amount >= price, "Insufficient payment");
        
        uint256 agreementId = nextAgreementId++;
        agreements[agreementId] = StorageAgreement({
            user: msg.sender,
            provider: provider,
            fileReference: "",
            size: size,
            duration: duration,
            price: price,
            startTime: block.timestamp,
            active: true
        });
        

        nodeRegistry.updateAvailableSpace(provider, size, false);
        
        userAgreements[msg.sender].push(agreementId);
        providerAgreements[provider].push(agreementId);
        
        MockUSDT.transferFrom(msg.sender, address(this), amount);

        emit AgreementCreated(agreementId, msg.sender, provider);
        
        return agreementId;
    }

    /// @notice store a file reference in the agreement
    /// @param agreementId - ID of the agreement
    /// @param fileReference - reference to the stored file
    function storeFile(uint256 agreementId, string calldata fileReference) external override {
        StorageAgreement storage agreement = agreements[agreementId];
        
        require(agreement.user == msg.sender, "Not agreement owner");
        require(agreement.active, "Agreement not active");
        require(!isAgreementExpired(agreementId), "Agreement has expired");
        require(bytes(agreement.fileReference).length == 0, "File already stored");
        
        agreement.fileReference = fileReference;
        
        emit FileStored(agreementId, fileReference);
    }
    
    /// @param agreementId - ID of the agreement
    function terminateAgreement(uint256 agreementId) external override {
        StorageAgreement storage agreement = agreements[agreementId];
        
        require(agreement.user == msg.sender || agreement.provider == msg.sender, "Not authorized");
        require(agreement.active, "Agreement already terminated");
        
        agreement.active = false;
        
        nodeRegistry.updateAvailableSpace(agreement.provider, agreement.size, true);
        
        if (block.timestamp >= agreement.startTime + (agreement.duration * 30 days)) {
            nodeRegistry.updateReputation(agreement.provider, 5);
        }
        
        emit AgreementTerminated(agreementId);
    }

    /// @param agreementId - ID of the agreement
    function terminateExpiredAgreement(uint256 agreementId) external {
        StorageAgreement storage agreement = agreements[agreementId];
        
        require(agreement.provider == msg.sender, "Only provider can terminate expired agreements");
        require(agreement.active, "Agreement already terminated");
        require(isAgreementExpired(agreementId), "Agreement has not expired yet");
        
        agreement.active = false;
        StorageNode(nodeRegistry).updateAvailableSpace(agreement.provider, agreement.size, true);
        
        emit AgreementTerminated(agreementId);
    }

    /// @param agreementId - ID of the agreement
    /// @param additionalMonths - duration to extend the agreement in months
    /// @param amount - amount for full duration
    function extendAgreement(uint256 agreementId, uint256 additionalMonths, uint256 amount) external {
        StorageAgreement storage agreement = agreements[agreementId];
        
        require(agreement.user == msg.sender, "Not agreement owner");
        require(agreement.active, "Agreement not active");
        
        IStorageNode.NodeInfo memory nodeInfo = nodeRegistry.getNodeDetails(agreement.provider);
        uint256 additionalPrice = agreement.size * nodeInfo.pricePerGB * additionalMonths;
        
        require(amount >= additionalPrice, "Insufficient payment");
        
        agreement.duration += additionalMonths;
        agreement.price += additionalPrice;
        
        MockUSDT.transferFrom(msg.sender, address(this), amount);
        
        emit AgreementExtended(agreementId, additionalMonths, additionalPrice);
    }


    ////////////////////view functions ///////////////////////
    function isAgreementExpired(uint256 agreementId) public view returns (bool) {
        StorageAgreement storage agreement = agreements[agreementId];
        return block.timestamp > agreement.startTime + (agreement.duration * 30 days);
    }
    
    function getAgreement(uint256 agreementId) external view override returns (StorageAgreement memory) {
        return agreements[agreementId];
    }
    
    function getUserAgreements(address user) external view returns (uint256[] memory) {
        return userAgreements[user];
    }
    
    function getProviderAgreements(address provider) external view returns (uint256[] memory) {
        return providerAgreements[provider];
    }
}
