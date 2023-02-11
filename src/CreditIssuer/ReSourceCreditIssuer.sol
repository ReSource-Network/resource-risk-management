// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./CreditIssuer.sol";
import "../interface/IReSourceCreditIssuer.sol";

import "forge-std/Test.sol";

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
    // network => maximum Income to Debt ratio
    mapping(address => uint256) minITD;

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
        if (amount > 0 || to != address(0)) {
            require(msg.sender == network, "ReSourceCreditIssuer: invalid tx data");
        }
        // update recipients terms.
        if (!periodExpired(network, to) || inGracePeriod(network, to)) {
            updateMemberTerms(network, to, amount);
        }
        // valid if sender does not have terms.
        if (creditPeriods[network][from].issueTimestamp == 0) return true;
        // valid if sender is not using credit.
        if (amount > 0 && amount <= IERC20Upgradeable(network).balanceOf(from)) return true;
        // if end of active credit period, handle expiration
        if (periodExpired(network, from)) {
            return handleExpired(network, from);
        }
        return true;
    }

    /* ========== VIEWS ========== */

    function hasRebalanced(address network, address member) public view returns (bool) {
        return creditTerms[network][member].rebalanced;
    }

    function hasValidITD(address network, address member) public view returns (bool) {
        if (itdOf(network, member) == -1) return true;
        return itdOf(network, member) >= int256(minITD[network]);
    }

    function itdOf(address network, address member) public view returns (int256) {
        // if no income, return 0
        if (creditTerms[network][member].periodIncome == 0) return 0;
        // if no debt, return indeterminate
        if (IMutualCredit(network).creditBalanceOf(member) == 0) return -1;
        // income / credit balance (in Parts Per Million)
        return int256(creditTerms[network][member].periodIncome * MAX_PPM)
            / int256(IMutualCredit(network).creditBalanceOf(member));
    }

    function neededIncomeOf(address network, address member) external view returns (uint256) {
        if (hasValidITD(network, member)) return 0;

        return (
            (minITD[network] * IMutualCredit(network).creditBalanceOf(member) / MAX_PPM)
                - creditTerms[network][member].periodIncome
        ) * MAX_PPM / ((minITD[network] + MAX_PPM)) + 1;
    }

    function isFrozen(address network, address member) public view returns (bool) {
        // member is frozen if in grace period, not paused, not rebalanced, and has invalid ITD
        return inGracePeriod(network, member) && !creditTerms[network][member].paused
            && !hasRebalanced(network, member) && !hasValidITD(network, member);
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

    function underwriteMember(address network, address member)
        public
        override
        onlyAuthorized(network)
        notNull(member)
    {
        super.underwriteMember(network, member);
        // TODO: use SBTs to get a starting point for creditLimit and feeRate
        // use risk oracle to add network context
        // initializeCreditLine(network, member, feeRate, creditLimit);
    }

    // manually assign member with credit terms
    function initializeCreditLine(
        address network,
        address member,
        uint256 feeRate,
        uint256 creditLimit,
        uint256 balance
    ) public onlyAuthorized(network) notNull(member) {
        // initialize credit period
        initializeCreditPeriod(network, member);
        // set member fee rate
        creditTerms[network][member].feeRate = feeRate;
        // initialize credit line
        IStableCredit(network).createCreditLine(member, creditLimit, balance);
    }

    function setMinITD(address network, uint256 _minITD) public onlyAuthorized(network) {
        minITD[network] = _minITD;
    }

    function pauseTermsOf(address network, address member) external onlyAuthorized(network) {
        creditTerms[network][member].paused = true;
    }

    function unpauseTermsOf(address network, address member) external onlyAuthorized(network) {
        creditTerms[network][member].paused = false;
    }

    function setReUnderwrite(address network, address member, bool status)
        external
        onlyAuthorized(network)
    {
        creditTerms[network][member].reUnderwrite = status;
    }

    /* ========== PRIVATE FUNCTIONS ========== */

    function initializeCreditPeriod(address network, address member) internal override {
        super.initializeCreditPeriod(network, member);
        creditTerms[network][member].rebalanced = false;
        creditTerms[network][member].periodIncome = 0;
    }

    /// @dev deletes credit terms and emits a default event if caller has outstanding debt.
    function expireCreditLine(address network, address member) internal override {
        delete creditTerms[network][member];
        super.expireCreditLine(network, member);
    }

    function updateMemberTerms(address network, address member, uint256 income) private {
        // record new period income
        creditTerms[network][member].periodIncome += income;
        // update rebalance status if possible
        if (income >= IMutualCredit(network).creditBalanceOf(member)) {
            creditTerms[network][member].rebalanced = true;
        }
    }

    function handleExpired(address network, address member) private returns (bool) {
        // if member has rebalanced or has a valid ITD, re-initialize credit line, and try re-underwrite
        if (hasRebalanced(network, member) || hasValidITD(network, member)) {
            initializeCreditPeriod(network, member);
            tryReUnderwriteMember(network, member);
            return true;
        }
        // if terms are paused for member, validate member
        if (creditTerms[network][member].paused) return true;
        // if member is in grace period, invalidate member
        if (inGracePeriod(network, member)) return false;
        // default member
        expireCreditLine(network, member);
        return false;
    }

    function tryReUnderwriteMember(address network, address member) private {
        if (creditTerms[network][member].reUnderwrite) {
            underwriteMember(network, member);
        }
    }

    /* ========== MODIFIERS ========== */

    modifier notNull(address member) {
        require(member != address(0), "ReSourceCreditIssuer: member address can't be null ");
        _;
    }
}
