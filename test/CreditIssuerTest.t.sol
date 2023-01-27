// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.13;

import "./ReSourceRiskManagementTest.t.sol";

contract CreditIssuerTest is ReSourceNetworkTest {
    function setUp() public {
        setUpStableCreditNetwork();
    }
}
