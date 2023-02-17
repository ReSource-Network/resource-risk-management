// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "./interface/IRiskManager.sol";

/// @title RiskManager contract
/// @author ReSource
/// @notice This contract interfaces with a network's "Credit Contracts" in order
/// to execute risk mitigation strategies.

contract RiskManager is OwnableUpgradeable, IRiskManager {
    /* ========== STATE VARIABLES ========== */

    IReservePool public reservePool;

    /* ========== INITIALIZER ========== */

    function initialize() external virtual initializer {
        __Ownable_init();
    }

    /* ========== PUBLIC FUNCTIONS ========== */

    function syncRiskVariables(address network) external {
        // TODO: implement this
        // retrieve RiskOracle's current predicted network default rate
        // translate predicted default rate to newTargetRTD and newBaseFeeRate
        // reservePool.setTargetRTD(network, newTargetRTD)
        // baseFeeRate[network] = newBaseFeeRate
    }

    /* ========== RESTRICTED FUNCTIONS ========== */

    /// @dev Replaces reservePool
    function setReservePool(address newReservePool) external onlyOwner {
        reservePool = IReservePool(newReservePool);
    }
}
