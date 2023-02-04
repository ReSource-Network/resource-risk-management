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

    /* ========== INITIALIZER ========== */

    function __CreditIssuer_init() public virtual onlyInitializing {
        __Ownable_init();
        __Pausable_init();
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    function validateTransaction(address network, address from, address to, uint256 amount)
        public
        virtual
        returns (bool)
    {}

    /* ========== VIEWS ========== */

    function periodExpired(address network, address member) public view returns (bool) {
        return block.timestamp >= creditPeriods[network][member].expirationTimestamp;
    }

    function inGoodStanding(address network, address member) public view virtual returns (bool) {}

    /* ========== RESTRICTED FUNCTIONS ========== */

    // intended to be overwritten in parent implementation
    function underwriteMember(address network, address member) public virtual {
        require(
            creditPeriods[network][member].issueTimestamp == 0,
            "RiskManager: member already has active credit period"
        );
        // << insert custom underwriting logic here >>
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
        }
        emit CreditPeriodExpired(network, member);
    }
}
