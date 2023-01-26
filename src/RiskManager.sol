// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@resource-stable-credit/interface/IStableCredit.sol";
import "./interface/IReservePool.sol";
import "./interface/IRiskManager.sol";

/// @title RiskManager contract
/// @author ReSource
/// @notice This contract interfaces with a network's "Credit Contracts" in order
/// to execute risk mitigation strategies.

contract RiskManager is OwnableUpgradeable, IRiskManager {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    /* ========== STATE VARIABLES ========== */

    IReservePool public reservePool;

    mapping(address => uint256) public baseFeeRate;

    /* ========== INITIALIZER ========== */

    function initialize() external virtual initializer {
        __Ownable_init();
    }

    /* ========== PUBLIC FUNCTIONS ========== */

    function depositFees(address network, uint256 amount) external override {
        IStableCredit(network).referenceToken().safeTransferFrom(msg.sender, address(this), amount);
        IStableCredit(network).referenceToken().approve(address(reservePool), amount);
        reservePool.depositFees(network, amount);
    }

    function depositPayment(address network, uint256 amount) external override {
        IStableCredit(network).referenceToken().safeTransferFrom(msg.sender, address(this), amount);
        IStableCredit(network).referenceToken().approve(address(reservePool), amount);
        reservePool.depositPayment(network, amount);
    }

    function syncRisk(address network) external {
        // TODO:
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

    function reimburseMember(address network, address member, uint256 amount) external override {
        require(msg.sender == network, "RiskManager: only network can reimburse member");
        reservePool.reimburseMember(network, member, amount);
    }

    function setBaseFeeRate(address network, uint256 _baseFeeRate) external onlyOwner {
        baseFeeRate[network] = _baseFeeRate;
    }

    function setTargetRTD(address network, uint256 _targetRTD) external onlyOwner {
        reservePool.setTargetRTD(network, _targetRTD);
    }
}
