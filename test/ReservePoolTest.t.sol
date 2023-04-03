// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./RiskManagementTest.t.sol";

contract ReservePoolTest is RiskManagementTest {
    function setUp() public {
        setUpReSourceTest();
        vm.startPrank(deployer);
        reserveToken.approve(address(reservePool), type(uint256).max);
        vm.stopPrank();
    }

    // deposit into primary reserve updates total reserve and primary reserve
    function testDepositIntoPrimaryReserve() public {
        // deposit reserve updates reserve in reserve pool
        vm.startPrank(deployer);
        uint256 amount = 100;
        // deposit into primary reserve
        reservePool.depositIntoPrimaryReserve(amount);
        // check total reserve
        assertEq(reservePool.reserveBalance(), amount);
        // check primary reserve
        assertEq(reservePool.primaryBalance(), amount);
        vm.stopPrank();
    }

    // deposit into peripheral reserve updates total reserve and peripheral reserve
    function testDepositIntoPeripheralReserve() public {
        vm.startPrank(deployer);
        uint256 amount = 100;
        // deposit into peripheral reserve
        reservePool.depositIntoPeripheralReserve(amount);
        // check total reserve
        assertEq(reservePool.reserveBalance(), amount);
        // check peripheral reserve
        assertEq(reservePool.peripheralBalance(), amount);
        vm.stopPrank();
    }

    // deposit needed reserves updates excess pool when RTD is above target
    function testDepositNeededWithHighRTD() public {
        // deposit fees updates fees in reserve pool
        vm.startPrank(deployer);
        uint256 amount = 100;
        // deposit into needed reserve
        reservePool.deposit(amount);
        // check excess reserve
        assertEq(reservePool.excessBalance(), amount);
        vm.stopPrank();
    }

    // deposit fees updates reserve when RTD is below target
    function testDepositFeesWithLowRTD() public {
        // deposit fees updates fees in reserve pool
        vm.startPrank(alice);
        // create 100 supply of credit token
        creditToken.mint(bob, 100);
        vm.stopPrank();
        vm.startPrank(deployer);
        uint256 amount = 100;
        // deposit into needed reserve
        reservePool.deposit(amount);
        assertEq(reservePool.reserveBalance(), 20);
        assertEq(reservePool.excessBalance(), 80);
        vm.stopPrank();
    }

    function testUpdateBaseFeeRate() public {
        // update base fee rate
        vm.startPrank(deployer);
        riskOracle.setBaseFeeRate(address(reservePool), 10000);
        assertEq(riskOracle.baseFeeRate(address(reservePool)), 10000);
        vm.stopPrank();
    }

    function testWithdraw() public {
        // withdraw from reserve pool
        vm.startPrank(deployer);
        uint256 amount = 100 * 10e18;
        reservePool.deposit(amount);
        assertEq(reserveToken.balanceOf(deployer), (1000000 * 10e18) - amount);
        assertEq(reservePool.excessBalance(), amount);
        reservePool.withdraw(amount);
        assertEq(reserveToken.balanceOf(deployer), (1000000 * 10e18));
        assertEq(reservePool.excessBalance(), 0);
        vm.stopPrank();
    }

    function testReimburseAccountWithPrimaryReserve() public {
        vm.startPrank(deployer);
        // deposit into primary reserve
        uint256 amount = 100 * 10e18;
        reservePool.depositIntoPrimaryReserve(amount);
        vm.stopPrank();
        vm.startPrank(address(creditToken));
        reservePool.reimburseAccount(bob, 10 * 10e18);
        assertEq(reservePool.primaryBalance(), 90 * 10e18);
        assertEq(reserveToken.balanceOf(bob), 10 * 10e18);
    }

    function testReimburseAccountWithPrimaryAndPeripheralReserve() public {
        vm.startPrank(deployer);
        // deposit into primary reserve
        uint256 amount = 100 * 10e18;
        reservePool.depositIntoPrimaryReserve(amount);
        // deposit into peripheral reserve
        reservePool.depositIntoPeripheralReserve(amount);
        vm.stopPrank();
        vm.startPrank(address(creditToken));
        reservePool.reimburseAccount(bob, 10 * 10e18);
        assertEq(reservePool.primaryBalance(), 100 * 10e18);
        assertEq(reservePool.peripheralBalance(), 90 * 10e18);
        assertEq(reserveToken.balanceOf(bob), 10 * 10e18);
    }

    function testConvertCreditTokenToReserveToken() public {
        assertEq(
            reservePool.convertCreditTokenToReserveToken(
                100 * (10 ** IERC20Metadata(address(creditToken)).decimals())
            ),
            100 * (10 ** IERC20Metadata(address(reserveToken)).decimals())
        );
    }

    function testReimburseAccountWithInsufficientReserve() public {
        vm.startPrank(deployer);
        // deposit into primary reserve
        uint256 amount = 25 * 10e18;
        reservePool.depositIntoPrimaryReserve(amount);
        // deposit into peripheral reserve
        reservePool.depositIntoPeripheralReserve(amount);
        vm.stopPrank();
        vm.startPrank(address(creditToken));
        reservePool.reimburseAccount(bob, 60 * 10e18);
        assertEq(reservePool.primaryBalance(), 0);
        assertEq(reservePool.peripheralBalance(), 0);
        assertEq(reserveToken.balanceOf(bob), 50 * 10e18);
    }

    function testNeededReserves() public {
        vm.startPrank(deployer);
        // create 100 supply of credit token
        creditToken.mint(bob, 100);
        // deposit 15% reserve tokens into primary reserve
        reservePool.depositIntoPrimaryReserve(15);
        assertEq(reservePool.neededReserves(), 5);
    }

    function testSetReserveToken() public {
        vm.startPrank(deployer);
        reservePool.setReserveToken(address(reserveToken));
        assertEq(address(reservePool.reserveToken()), address(reserveToken));
        vm.stopPrank();
    }

    function testSetRiskOracle() public {
        vm.startPrank(deployer);
        reservePool.setRiskOracle(address(riskOracle));
        assertEq(address(reservePool.riskOracle()), address(riskOracle));
        vm.stopPrank();
    }

    function testRTDWithNoDebt() public {
        vm.startPrank(deployer);
        uint256 rtd = reservePool.RTD();
        assertEq(rtd, 0);
        vm.stopPrank();
    }

    function testSetTargetRTD() public {
        vm.startPrank(deployer);
        reservePool.setTargetRTD(100 * 1e18);
        assertEq(reservePool.targetRTD(), 100 * 1e18);
        vm.stopPrank();
    }

    function testSetTargetRTDWithNeededReserves() public {
        vm.startPrank(deployer);
        // create 100 supply of credit token
        creditToken.mint(bob, 100);
        // deposit into excess reserve
        reservePool.depositIntoExcessReserve(100);
        // set target RTD to 100%
        reservePool.setTargetRTD(100 * 10e16);
        // check that excess reserve was moved to primary reserve
        assertEq(reservePool.primaryBalance(), 100);
        assertEq(reservePool.excessBalance(), 0);
        vm.stopPrank();
    }

    function testSetTargetRTDWithPartiallyNeededReserves() public {
        vm.startPrank(deployer);
        // create 100 supply of credit token
        creditToken.mint(bob, 100);
        // deposit 15% reserve tokens into primary reserve
        reservePool.depositIntoPrimaryReserve(15);
        // deposit into excess reserve
        reservePool.depositIntoExcessReserve(100);
        // change target RTD to 25%
        reservePool.setTargetRTD(25e16);
        // check that excess reserve was moved to primary reserve
        assertEq(reservePool.primaryBalance(), 25);
        assertEq(reservePool.excessBalance(), 90);
        vm.stopPrank();
    }
}
