// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./CreditIssuer.sol";
import "../interface/IReSourceCreditIssuer.sol";

/// @title ReSourceCreditIssuer
/// @author ReSource
/// @notice Issue Credit to network members and manage credit terms
contract ReSourceCreditIssuer is CreditIssuer, IReSourceCreditIssuer {
    /* ========== CONSTANTS ========== */

    /// @dev Maximum parts per million
    uint32 private constant MAX_PPM = 1000000;

    /* ========== STATE VARIABLES ========== */
    // network => member => period
    mapping(address => mapping(address => CreditTerm)) public creditTerms;
    // network => past due cut off time
    mapping(address => uint256) pastDueCutoff;
    // network => default cut off time
    mapping(address => uint256) defaultCutoff;
    // network => minimum Debt to Income ratio
    mapping(address => uint256) minDTI;

    /* ========== INITIALIZER ========== */

    function initialize() public virtual initializer {
        __CreditIssuer_init();
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    function validateTransaction(address network, address from, address to, uint256 amount)
        public
        override
        returns (bool)
    {
        // update recipients terms.
        if (!periodExpired(network, to)) updateMemberTerms(network, to, amount);
        // valid if sender does not have terms.
        if (creditPeriods[network][from].issueTimestamp == 0) return true;
        // valid if sender is not using credit.
        if (amount <= IERC20Upgradeable(network).balanceOf(from)) return true;
        // if is past due
        if (isPastDue(network, from)) {
            return handlePastDue(network, from);
        }
        // if end of active credit period either re underwrite or default member
        if (periodExpired(network, from)) {
            return handleExpired(network, from);
        }
        return true;
    }

    /* ========== VIEWS ========== */

    function inGoodStanding(address network, address member) public view override returns (bool) {
        // have met dti minimum and has rebalanced at least once
        return dtiOf(network, member) >= minDTI[network] && creditTerms[network][member].rebalanced;
    }

    function isPastDue(address network, address member) public view returns (bool) {
        return block.timestamp
            >= creditPeriods[network][member].issueTimestamp + pastDueCutoff[network]
            && !periodExpired(network, member);
    }

    function dtiOf(address network, address member) public view returns (uint256) {
        return (IMutualCredit(network).creditBalanceOf(member) * MAX_PPM)
            / creditTerms[network][member].periodIncome;
    }

    function creditTermsOf(address network, address member)
        public
        view
        override
        returns (CreditTerm memory)
    {
        return creditTerms[network][member];
    }

    /* ========== RESTRICTED FUNCTIONS ========== */

    function underwriteMember(address network, address member) public override {
        super.underwriteMember(network, member);
        // TODO: use SBTs to get a starting point for creditLimit and feeRate
        // use risk oracle to add network context
        // initializeCreditLine(network, member, feeRate, creditLimit);
    }

    // manually assign member with credit terms
    // TODO: add function role access
    function initializeCreditLine(
        address network,
        address member,
        uint256 feeRate,
        uint256 creditLimit,
        uint256 balance
    ) public {
        initializeCreditPeriod(network, member, defaultCutoff[network]);
        creditTerms[network][member].feeRate = feeRate;
        IStableCredit(network).createCreditLine(member, creditLimit, balance);
    }

    /* ========== PRIVATE FUNCTIONS ========== */

    /// @dev deletes credit terms and emits a default event if caller has outstanding debt.
    function expireCreditLine(address network, address member) internal override {
        super.expireCreditLine(network, member);
        delete creditTerms[network][member];
    }

    function updateMemberTerms(address network, address member, uint256 income) private {
        if (income > 0) require(msg.sender == network, "ReSourceCreditIssuer: invalid tx data");
        // record new period income
        creditTerms[network][member].periodIncome += income;
        // update rebalance status if possible
        if (
            IMutualCredit(network).creditBalanceOf(member) > 0
                && income > IMutualCredit(network).creditBalanceOf(member)
        ) creditTerms[network][member].rebalanced = true;
    }

    function handlePastDue(address network, address member) private returns (bool) {
        if (!inGoodStanding(network, member)) {
            creditTerms[network][member].wasPastDue = true;
            return false;
        }
        if (creditTerms[network][member].wasPastDue) {
            // calculate new credit limit derived from minDTI of network
            uint256 newLimit = IMutualCredit(network).creditBalanceOf(member)
                - (IMutualCredit(network).creditBalanceOf(member) * minDTI[network] / MAX_PPM);
            // update credit line with newly contracted limit
            IStableCredit(network).updateCreditLimit(member, newLimit);
            creditTerms[network][member].wasPastDue = false;
        }
        return true;
    }

    function handleExpired(address network, address member) private returns (bool) {
        if (inGoodStanding(network, member)) {
            underwriteMember(network, member);
            // if underwrite function does not revert, then valid transaction
            return true;
        }
        // default member
        expireCreditLine(network, member);
        return false;
    }
}
