// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IReSourceCreditIssuer {
    struct CreditTerm {
        bool rebalanced;
        bool wasPastDue;
        uint256 periodIncome;
        uint256 feeRate;
    }

    function creditTermsOf(address network, address member)
        external
        view
        returns (CreditTerm memory);
}
