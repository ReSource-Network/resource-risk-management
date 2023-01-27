// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../src/CreditIssuer.sol";

/// @title ReSourceCreditIssuer
/// @author ReSource
/// @notice Issue Credit to network members and manage credit terms
contract MockCreditIssuer is CreditIssuer {
    /* ========== INITIALIZER ========== */

    function initialize() external virtual initializer {
        __CreditIssuer_init();
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    /// @notice Defaults expired credit lines.
    /// @dev publically exposed for state synchronization. Returns true if line is valid.
    function validateCreditLine(address network, address member) public override returns (bool) {
        require(
            IMutualCredit(network).creditLimitOf(member) > 0,
            "StableCredit: member does not have a credit line"
        );
        if (!isActivePeriod(network, member)) {
            expireCreditLine(network, member);
            return false;
        }
        return true;
    }

    /* ========== RESTRICTED FUNCTIONS ========== */

    function underwriteMember(address network, address member)
        external
        override
        onlyOperator(msg.sender)
    {
        super.underwriteMember(network, member);
        uint256 expirationTimestamp = block.timestamp + 90 days;
        uint256 creditLimit = 1000;
        uint256 feeRate = 100000; // 10%
        initializeCreditPeriod(network, member, expirationTimestamp);
        IStableCredit(network).feeManager().setMemberFeeRate(member, _feeRate);
        IStableCredit(network).createCreditLine(member, creditLimit, 0);
    }

    /* ========== MODIFIERS ========== */

    modifier onlyOperator(address network) {
        require(
            IStableCredit(network).access().isOperator(msg.sender) || msg.sender == owner(),
            "ReservePool: Caller is not operator"
        );
        _;
    }
}
