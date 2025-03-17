// contracts/StorageNode.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "../interfaces/IStorageNode.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract StorageNode is IStorageNode,Ownable(msg.sender) {
    address public storageMarketAddress;
    mapping(address => NodeInfo) public nodes;
    
    event NodeRegistered(address indexed owner, uint256 availableSpace, uint256 pricePerGB);
    event NodeUpdated(address indexed owner, uint256 availableSpace, uint256 pricePerGB, bool active);
    
    modifier onlyRegisteredNode() {
        require(nodes[msg.sender].owner == msg.sender, "Not a registered node");
        _;
    }

    modifier onlyStorageMarket() {
        require(msg.sender == storageMarketAddress, "Only StorageMarket can call");
        _;
    }

    function setStorageMarketAddress(address _storageMarketAddress) external onlyOwner() {
        storageMarketAddress = _storageMarketAddress;
    }
    
    /// @notice Registers a new storage node.
    /// @param availableSpace - The amount of storage space available in GB.
    /// @param pricePerGB - The price per GB in Wei.
    function registerNode(uint256 availableSpace, uint256 pricePerGB) external override {
        require(nodes[msg.sender].owner == address(0), "Node already registered");
        require(availableSpace > 0, "Must provide storage space");
        require(pricePerGB > 0, "Price must be greater than 0");
        
        nodes[msg.sender] = NodeInfo({
            owner: msg.sender,
            availableSpace: availableSpace,
            pricePerGB: pricePerGB,
            active: true,
            reputation: 100 // Starting reputation
        });
        
        emit NodeRegistered(msg.sender, availableSpace, pricePerGB);
    }
    
    /// @notice allows a registered node to update its storage offering details.
    /// @param availableSpace -  new amount of storage space (in GB) the node is offering.
    /// @param pricePerGB - new price per GB (in Wei) the node is charging.
    /// @param active - whether the node is currently active or not.
    function updateNodeDetails(uint256 availableSpace, uint256 pricePerGB, bool active) external override onlyRegisteredNode {
        NodeInfo storage node = nodes[msg.sender];
        node.availableSpace = availableSpace;
        node.pricePerGB = pricePerGB;
        node.active = active;
        
        emit NodeUpdated(msg.sender, availableSpace, pricePerGB, active);
    }
    
    function getNodeDetails(address nodeAddress) external view override returns (NodeInfo memory) {
        return nodes[nodeAddress];
    }
    
    /// @notice Updates the available space of a registered node, called by marketplace when creating or terminating an agreement..
    /// @param nodeAddress - The address of the node.
    /// @param spaceUsed - The amount of space used or freed.
    /// @param increase - If true, increases the available space, otherwise decreases it.
    function updateAvailableSpace(address nodeAddress, uint256 spaceUsed, bool increase) public override onlyStorageMarket{
        NodeInfo storage node = nodes[nodeAddress];
        require(node.owner != address(0), "Node not registered");
        
        if (increase) {
            node.availableSpace += spaceUsed;
        } else {
            require(node.availableSpace >= spaceUsed, "Not enough available space");
            node.availableSpace -= spaceUsed;
        }
    }
    
    /// @notice Updates the reputation of a node based on the score provided, also called by marketplace.
    /// @param nodeAddress - The address of the node.
    /// @param score - The score to add or subtract from the node's reputation.
    function updateReputation(address nodeAddress, uint8 score) public  override onlyStorageMarket{
        NodeInfo storage node = nodes[nodeAddress];
        require(node.owner != address(0), "Node not registered");
        if (score > 0 && node.reputation < 1000) {
            node.reputation += score;
        } else if (score == 0 && node.reputation > 10) {
            node.reputation -= 10;
        }
    }
}
