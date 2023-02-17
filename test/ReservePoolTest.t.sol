// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./ReSourceTest.t.sol";

contract ReservePoolTest is ReSourceTest {
    function setUp() public {
        setUpReSourceTest();
        vm.startPrank(deployer);
        stableCredit.createCreditLine(alice, 100, 0);
        stableCredit.referenceToken().approve(address(reservePool), type(uint256).max);
        vm.stopPrank();
    }

    // deposit into primary reserve updates total reserve and primary reserve
    function testDepositIntoPrimaryReserve() public {
        // deposit reserve updates reserve in reserve pool
        vm.startPrank(deployer);
        uint256 amount = 100;
        // approve reference token
        stableCredit.referenceToken().approve(address(riskManager), amount);
        // deposit into primary reserve
        reservePool.depositIntoPrimaryReserve(
            address(stableCredit), address(stableCredit.referenceToken()), amount
        );
        // check total reserve
        assertEq(
            reservePool.totalReserveOf(
                address(stableCredit), address(stableCredit.referenceToken())
            ),
            amount
        );
        // check primary reserve
        assertEq(
            reservePool.primaryReserve(
                address(stableCredit), address(stableCredit.referenceToken())
            ),
            amount
        );
        vm.stopPrank();
    }

    // deposit into peripheral reserve updates total reserve and peripheral reserve
    function testDepositIntoPeripheralReserve() public {
        vm.startPrank(deployer);
        uint256 amount = 100;
        // approve reference token
        stableCredit.referenceToken().approve(address(riskManager), amount);
        // deposit into peripheral reserve
        reservePool.depositIntoPeripheralReserve(
            address(stableCredit), address(stableCredit.referenceToken()), amount
        );
        // check total reserve
        assertEq(
            reservePool.totalReserveOf(
                address(stableCredit), address(stableCredit.referenceToken())
            ),
            amount
        );
        // check peripheral reserve
        assertEq(
            reservePool.peripheralReserve(
                address(stableCredit), address(stableCredit.referenceToken())
            ),
            amount
        );
        vm.stopPrank();
    }

    // deposit needed reserves updates excess pool when RTD is above target
    function testDepositNeededWithHighRTD() public {
        // deposit fees updates fees in reserve pool
        vm.startPrank(deployer);
        uint256 amount = 100;
        // approve reference token
        stableCredit.referenceToken().approve(address(riskManager), amount);
        // deposit into needed reserve
        reservePool.depositIntoNeededReserve(
            address(stableCredit), address(stableCredit.referenceToken()), amount
        );
        // check excess reserve
        assertEq(
            reservePool.excessReserve(address(stableCredit), address(stableCredit.referenceToken())),
            amount
        );
        vm.stopPrank();
    }

    // deposit fees updates reserve when RTD is below target
    function testDepositFeesWithLowRTD() public {
        // deposit fees updates fees in reserve pool
        vm.startPrank(alice);
        stableCredit.transfer(bob, 100);
        vm.stopPrank();
        vm.startPrank(deployer);
        uint256 amount = 100;
        // approve reference token
        stableCredit.referenceToken().approve(address(riskManager), amount);
        // deposit into needed reserve
        reservePool.depositIntoNeededReserve(
            address(stableCredit), address(stableCredit.referenceToken()), amount
        );
        assertEq(
            reservePool.totalReserveOf(
                address(stableCredit), address(stableCredit.referenceToken())
            ),
            amount
        );
        vm.stopPrank();
    }

    function testUpdateBaseFeeRate() public {
        // update base fee rate
        vm.startPrank(deployer);
        reservePool.setBaseFeeRate(address(stableCredit), 10000);
        assertEq(reservePool.baseFeeRate(address(stableCredit)), 10000);
        vm.stopPrank();
    }
}
