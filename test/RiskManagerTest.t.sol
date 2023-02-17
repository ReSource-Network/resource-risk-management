// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./ReSourceTest.t.sol";

contract RiskManagerTest is ReSourceTest {
    function setUp() public {
        setUpReSourceTest();
        vm.startPrank(deployer);
        stableCredit.createCreditLine(alice, 100, 0);
        vm.stopPrank();
    }

    // TODO: testSyncRisk function
    //      uses predicted default rate provided by RiskOracle to update baseFeeRate and targetRTD
}
