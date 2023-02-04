// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.13;

import "./ReSourceTest.t.sol";

contract RiskManagerTest is ReSourceTest {
    address alice;
    address bob;

    function setUp() public {
        setUpReSourceTest();
        alice = address(2);
        bob = address(3);
        vm.deal(alice, 100 ether);
        vm.deal(bob, 100 ether);
        vm.startPrank(deployer);
        stableCredit.createCreditLine(alice, 100, 0);
        vm.stopPrank();
    }

    // testInitializeCreditLine

    // testValidateCreditLine

    // TODO: testUnderwriteMember
}
