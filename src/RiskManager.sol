// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "./interface/IStableCredit.sol";
import "./interface/IReservePool.sol";
import "./interface/IRiskManager.sol";

/// @title RiskManager contract
/// @author ReSource
/// @notice This contract interfaces with a network's "Credit Contracts" in order
/// to execute risk mitigation strategies.

contract RiskManager is OwnableUpgradeable, IRiskManager {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    /* ========== STATE VARIABLES ========== */

    IReservePool public _reservePool;

    mapping(address => uint256) public baseFeeRate;

    /* ========== INITIALIZER ========== */

    function initialize() external virtual initializer {
        __Ownable_init();
    }

    /* ========== VIEWS ========== */

    function reservePool() external view override returns (address) {
        return address(_reservePool);
    }

    /* ========== PUBLIC FUNCTIONS ========== */

    function depositFees(address network, uint256 amount) external override {
        IStableCredit(network).referenceToken().safeTransferFrom(msg.sender, address(this), amount);
        _reservePool.depositFees(network, amount);
    }

    function depositPayment(address network, uint256 amount) external override {
        IStableCredit(network).referenceToken().safeTransferFrom(msg.sender, address(this), amount);
        _reservePool.depositPayment(network, amount);
    }

    /* ========== RESTRICTED FUNCTIONS ========== */

    // TODO: add update function to check RiskOracle's predicted network default rate and update baseFee

    function setBaseFeeRate(address network, uint256 _baseFeeRate) external onlyOwner {
        baseFeeRate[network] = _baseFeeRate;
    }

    /// @dev Replaces reservePool
    function setReservePool(address newReservePool) external onlyOwner {
        _reservePool = IReservePool(newReservePool);
    }

    function reimburseMember(address network, address member, uint256 amount) external override {
        require(msg.sender == network, "RiskManager: only network can reimburse member");
        _reservePool.reimburseMember(network, member, amount);
    }
}
