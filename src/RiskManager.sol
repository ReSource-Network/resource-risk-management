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

    // TODO: implement
    /// @notice Responsible for syncing the the network risk variables of a given network to the
    /// calculated risk state provided by the RiskOracle.
    /// @dev This function is intended to be called on regularly scheduled intervals and can be
    /// called by any address.
    /// @param network address of credit network to update risk variables for
    function syncRiskVariables(address network) external {
        // retrieve network's current predicted network default rate from RiskOracle
        // translate predicted default rate to newTargetRTD and newBaseFeeRate
        // reservePool.setTargetRTD(network, newTargetRTD)
        // reservePool.setBaseFeeRate(network, newBaseFeeRate)
    }

    /* ========== RESTRICTED FUNCTIONS ========== */

    /// @dev Replaces reservePool
    function setReservePool(address newReservePool) external onlyOwner {
        reservePool = IReservePool(newReservePool);
    }
}
