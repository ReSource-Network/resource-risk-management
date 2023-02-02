// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "../interface/IStableCredit.sol";
import "../interface/IMutualCredit.sol";
import "../interface/ICreditIssuer.sol";

/// @title CreditIssuer
/// @author ReSource
/// @notice Issue Credit to network members and manage credit terms
contract CreditIssuer is ICreditIssuer, PausableUpgradeable, OwnableUpgradeable {
    struct CreditPeriod {
        uint256 issueTimestamp;
        uint256 expirationTimestamp;
    }

    /* ========== STATE VARIABLES ========== */

    // network => member => period
    mapping(address => mapping(address => CreditPeriod)) public creditPeriods;

    /* ========== INITIALIZER ========== */

    function __CreditIssuer_init() public virtual onlyInitializing {
        __Ownable_init();
        __Pausable_init();
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    /// @notice Defaults expired credit lines.
    /// @dev publically exposed for state synchronization. Returns true if line is valid.
    function validateCreditLine(address network, address member) public virtual returns (bool) {
        require(
            IMutualCredit(network).creditLimitOf(member) > 0,
            "StableCredit: member does not have a credit line"
        );
        if (!inActivePeriod(network, member)) {
            expireCreditLine(network, member);
            return false;
        }
        return true;
    }

    /* ========== VIEWS ========== */

    function inActivePeriod(address network, address member) public view returns (bool) {
        return creditPeriods[network][member].issueTimestamp == 0
            ? false
            : block.timestamp < creditPeriods[network][member].expirationTimestamp;
    }

    /* ========== RESTRICTED FUNCTIONS ========== */

    // intended to be overwritten in parent implementation
    function underwriteMember(address network, address member) public virtual {
        require(
            creditPeriods[network][member].issueTimestamp == 0,
            "RiskManager: member already in active credit period"
        );
        // calculate expirationTimestamp (ex. uint256 expirationTimestamp = block.timestamp + 90 days;)
        // calculate creditLimit (ex. uint256 creditLimit = 1000;)
        // calcualte member feeRate (ex. uint256 feeRate = 100000; // 10%)
        // initialize credit period (ex. initializeCreditPeriod(network, member, expirationTimestamp);)
        // set member fee rate (ex. IStableCredit(network).feeManager().setMemberFeeRate(member, _feeRate);)
        // create credit line (ex. IStableCredit(network).createCreditLine(member, creditLimit, 0);)
    }

    /* ========== PRIVATE FUNCTIONS ========== */

    function initializeCreditPeriod(address network, address member, uint256 _expirationTimestamp)
        internal
    {
        creditPeriods[network][member] = CreditPeriod({
            issueTimestamp: block.timestamp,
            expirationTimestamp: _expirationTimestamp
        });
        emit CreditPeriodCreated(network, member, _expirationTimestamp);
    }

    /// @dev deletes credit terms and emits a default event if caller has outstanding debt.
    function expireCreditLine(address network, address member) internal virtual {
        uint256 creditBalance = IMutualCredit(network).creditBalanceOf(member);
        delete creditPeriods[network][member];
        if (creditBalance > 0) {
            IStableCredit(network).writeOffCreditLine(member);
            emit CreditLineDefaulted(network, member);
            return;
        }
        emit CreditPeriodExpired(network, member);
    }
}
