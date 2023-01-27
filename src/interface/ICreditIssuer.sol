// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ICreditIssuer {
    function validateCreditLine(address network, address member) external returns (bool);

    event CreditLineDefaulted(address network, address member);

    event CreditPeriodExpired(address network, address member);

    event CreditPeriodCreated(address network, address member, uint256 defaultTime);
}
