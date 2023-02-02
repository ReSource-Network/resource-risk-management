// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./CreditIssuer.sol";

/// @title ReSourceCreditIssuer
/// @author ReSource
/// @notice Issue Credit to network members and manage credit terms
contract ReSourceCreditIssuer is CreditIssuer {
    // TODO: add other credit terms

    /* ========== STATE VARIABLES ========== */
    // network => member => period
    mapping(address => mapping(address => uint256)) public periodIncome;

    /* ========== INITIALIZER ========== */

    function initialize() public virtual initializer {
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
        // TODO: custom credit term validation
        if (!inActivePeriod(network, member)) {
            expireCreditLine(network, member);
            return false;
        }
        return true;
    }

    /* ========== VIEWS ========== */
    function periodIncomeOf(address network, address member) public view returns (uint256) {
        return periodIncome[network][member];
    }

    /* ========== RESTRICTED FUNCTIONS ========== */

    // intended to be overwritten in parent implementation
    function underwriteMember(address network, address member) public override {
        super.underwriteMember(network, member);
        // TODO:
        // calculate expirationTimestamp (ex. uint256 expirationTimestamp = block.timestamp + 90 days;)
        // calculate creditLimit (ex. uint256 creditLimit = 1000;)
        // calcualte member feeRate (ex. uint256 feeRate = 100000; // 10%)
        // initialize credit period (ex. initializeCreditPeriod(network, member, expirationTimestamp);)
        // set member fee rate (ex. IStableCredit(network).feeManager().setMemberFeeRate(member, _feeRate);)
        // other custom credit terms (ex. periodIncome[network][member] = 0))
        // create credit line (ex. IStableCredit(network).createCreditLine(member, creditLimit, 0);)
    }

    /* ========== PRIVATE FUNCTIONS ========== */

    /// @dev deletes credit terms and emits a default event if caller has outstanding debt.
    function expireCreditLine(address network, address member) internal override {
        super.expireCreditLine(network, member);
        //    TODO: periodIncome[network][member] = 0;
    }
}
