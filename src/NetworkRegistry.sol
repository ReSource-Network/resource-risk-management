// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

/// @title This contract is responsible for maintaining a list of networks
/// @author The name
/// @notice Explain to an end user what this does
/// @dev Explain to a developer any extra details
contract NetworkRegistry is Ownable {
    // address => isRegistered
    mapping(address => bool) public networks;

    /// @notice Allows owner address to add networks to the registry
    /// @dev The caller must be the owner of the contract
    /// @param network address of the network to add
    function addNetwork(address network) external onlyOwner {
        require(!networks[network], "Registry: Network is already registered");
        networks[network] = true;
        emit NetworkAdded(network);
    }

    /// @notice Allows owner address to remove networks to the registry
    /// @dev The caller must be the owner of the contract
    /// @param network address of the network to remove
    function removeNetwork(address network) external onlyOwner {
        require(networks[network], "Registry: Network isn't registered");
        networks[network] = false;
        emit NetworkRemoved(network);
    }

    event NetworkAdded(address network);
    event NetworkRemoved(address network);
}
