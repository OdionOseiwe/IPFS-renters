// contracts/interfaces/IStorageNode.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface IStorageNode {
    struct NodeInfo {
        address owner;
        uint256 availableSpace;
        uint256 pricePerGB;
        bool active;
        uint256 reputation;
    }
    
    function registerNode(uint256 availableSpace, uint256 pricePerGB) external;
    function updateNodeDetails(uint256 availableSpace, uint256 pricePerGB, bool active) external;
    function getNodeDetails(address nodeAddress) external view returns (NodeInfo memory);
    function updateAvailableSpace(address nodeAddress, uint256 spaceUsed, bool increase) external ;
    function updateReputation(address nodeAddress, uint8 score) external;
}
