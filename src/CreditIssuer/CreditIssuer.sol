// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@resource-stable-credit/interface/IStableCredit.sol";
import "@resource-stable-credit/interface/IMutualCredit.sol";

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
    // network => period length in seconds
    mapping(address => uint256) periodLength;
    // network => grace period length in seconds
    mapping(address => uint256) gracePeriodLength;

    /* ========== INITIALIZER ========== */

    function __CreditIssuer_init() public virtual onlyInitializing {
        __Ownable_init();
        __Pausable_init();
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    function validateTransaction(address network, address from, address to, uint256 amount)
        external
        onlyNetwork(network)
        returns (bool)
    {
        return _validateTransaction(network, from, to, amount);
    }

    function syncCreditLine(address network, address member) external returns (bool) {
        return _validateTransaction(network, member, address(0), 0);
    }

    /* ========== VIEWS ========== */

    function inActivePeriod(address network, address member) public view returns (bool) {
        return creditPeriods[network][member].expirationTimestamp > 0
            && block.timestamp
                < creditPeriods[network][member].expirationTimestamp + gracePeriodLength[network];
    }

    function inGracePeriod(address network, address member) public view returns (bool) {
        return periodExpired(network, member)
            && block.timestamp
                < creditPeriods[network][member].expirationTimestamp + gracePeriodLength[network];
    }

    function periodExpired(address network, address member) public view returns (bool) {
        return block.timestamp >= creditPeriods[network][member].expirationTimestamp;
    }

    function periodExpirationOf(address network, address member) public view returns (uint256) {
        return creditPeriods[network][member].expirationTimestamp;
    }

    /* ========== RESTRICTED FUNCTIONS ========== */

    // intended to be overwritten in parent implementation
    function underwriteMember(address network, address member) public virtual {
        require(
            !inActivePeriod(network, member), "RiskManager: member already in active credit period"
        );
        // << insert underwriting logic >>
    }

    function setPeriodLength(address network, uint256 _periodLength)
        public
        onlyAuthorized(network)
    {
        periodLength[network] = _periodLength;
    }

    function setGracePeriodLength(address network, uint256 _gracePeriodLength)
        public
        onlyAuthorized(network)
    {
        gracePeriodLength[network] = _gracePeriodLength;
    }

    /* ========== PRIVATE FUNCTIONS ========== */

    function initializeCreditPeriod(address network, address member) internal virtual {
        creditPeriods[network][member] = CreditPeriod({
            issueTimestamp: block.timestamp,
            expirationTimestamp: block.timestamp + periodLength[network]
        });
        emit CreditPeriodCreated(network, member, block.timestamp + periodLength[network]);
    }

    /// @dev deletes credit terms and emits a default event if caller has outstanding debt.
    function expireCreditLine(address network, address member) internal virtual {
        uint256 creditBalance = IMutualCredit(network).creditBalanceOf(member);
        delete creditPeriods[network][member];
        if (creditBalance > 0) {
            IStableCredit(network).writeOffCreditLine(member);
            IStableCredit(network).updateCreditLimit(member, 0);
            emit CreditLineDefaulted(network, member);
        }
        emit CreditPeriodExpired(network, member);
    }

    /**
     * @dev Hook that is called before any transfer of credits
     */
    function _validateTransaction(address network, address from, address to, uint256 amount)
        internal
        virtual
        returns (bool)
    {
        // << Insert tx validation logic >>
    }

    /* ========== MODIFIERS ========== */

    modifier onlyAuthorized(address network) {
        require(
            IStableCredit(network).access().isOperator(msg.sender) || owner() == msg.sender,
            "FeeManager: Unauthorized caller"
        );
        _;
    }

    modifier onlyNetwork(address network) {
        require(msg.sender == network, "ReSourceCreditIssuer: can only be called by network");
        _;
    }
}
