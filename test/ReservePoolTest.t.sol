// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./RiskManagementTest.t.sol";

contract ReservePoolTest is RiskManagementTest {
    function setUp() public {
        setUpReSourceTest();
        changePrank(deployer);
        reserveToken.approve(address(reservePool), type(uint256).max);
    }

    // deposit into primary reserve updates total reserve and primary reserve
    function testDepositIntoPrimaryReserve() public {
        // deposit reserve updates reserve in reserve pool
        changePrank(deployer);
        uint256 amount = 100;
        // deposit into primary reserve
        reservePool.depositIntoPrimaryReserve(amount);
        // check total reserve
        assertEq(reservePool.reserveBalance(), amount);
        // check primary reserve
        assertEq(reservePool.primaryBalance(), amount);
    }

    // deposit into peripheral reserve updates total reserve and peripheral reserve
    function testDepositIntoPeripheralReserve() public {
        changePrank(deployer);
        uint256 amount = 100;
        // deposit into peripheral reserve
        reservePool.depositIntoPeripheralReserve(amount);
        // check total reserve
        assertEq(reservePool.reserveBalance(), amount);
        // check peripheral reserve
        assertEq(reservePool.peripheralBalance(), amount);
    }

    // deposit needed reserves updates excess pool when RTD is above target
    function testDepositNeededWithHighRTD() public {
        // deposit fees updates fees in reserve pool
        changePrank(deployer);
        uint256 amount = 100;
        // deposit into needed reserve
        reservePool.deposit(amount);
        // check excess reserve
        assertEq(reservePool.excessBalance(), amount);
    }

    // deposit fees updates reserve when RTD is below target
    function testDepositFeesWithLowRTD() public {
        // deposit fees updates fees in reserve pool
        changePrank(alice);
        // create 100 supply of credit token
        creditToken.mint(bob, 100);
        changePrank(deployer);
        uint256 amount = 100;
        // deposit into needed reserve
        reservePool.deposit(amount);
        assertEq(reservePool.reserveBalance(), 20);
        assertEq(reservePool.excessBalance(), 80);
    }

    function testUpdateBaseFeeRate() public {
        // update base fee rate
        changePrank(deployer);
        riskOracle.setBaseFeeRate(address(reservePool), 10000);
        assertEq(riskOracle.baseFeeRate(address(reservePool)), 10000);
    }

    function testWithdraw() public {
        // withdraw from reserve pool
        changePrank(deployer);
        uint256 amount = 100 * 10e18;
        reservePool.deposit(amount);
        assertEq(reserveToken.balanceOf(deployer), (1000000 * 10e18) - amount);
        assertEq(reservePool.excessBalance(), amount);
        reservePool.withdraw(amount);
        assertEq(reserveToken.balanceOf(deployer), (1000000 * 10e18));
        assertEq(reservePool.excessBalance(), 0);
    }

    function testReimburseAccountWithPrimaryReserve() public {
        changePrank(deployer);
        // deposit into primary reserve
        uint256 amount = 100 * 10e18;
        reservePool.depositIntoPrimaryReserve(amount);
        changePrank(address(creditToken));
        reservePool.reimburseAccount(bob, 10 * 10e18);
        assertEq(reservePool.primaryBalance(), 90 * 10e18);
        assertEq(reserveToken.balanceOf(bob), 10 * 10e18);
    }

    function testReimburseAccountWithPrimaryAndPeripheralReserve() public {
        changePrank(deployer);
        // deposit into primary reserve
        uint256 amount = 100 * 10e18;
        reservePool.depositIntoPrimaryReserve(amount);
        // deposit into peripheral reserve
        reservePool.depositIntoPeripheralReserve(amount);
        changePrank(address(creditToken));
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

    function testConvertReserveTokenToCreditToken() public {
        assertEq(
            reservePool.convertReserveTokenToCreditToken(
                100 * (10 ** IERC20Metadata(address(reserveToken)).decimals())
            ),
            100 * (10 ** IERC20Metadata(address(creditToken)).decimals())
        );
    }

    function testReimburseAccountWithInsufficientReserve() public {
        changePrank(deployer);
        // deposit into primary reserve
        uint256 amount = 25 * 10e18;
        reservePool.depositIntoPrimaryReserve(amount);
        // deposit into peripheral reserve
        reservePool.depositIntoPeripheralReserve(amount);
        changePrank(address(creditToken));
        reservePool.reimburseAccount(bob, 60 * 10e18);
        assertEq(reservePool.primaryBalance(), 0);
        assertEq(reservePool.peripheralBalance(), 0);
        assertEq(reserveToken.balanceOf(bob), 50 * 10e18);
    }

    function testNeededReserves() public {
        changePrank(deployer);
        // create 100 supply of credit token
        creditToken.mint(bob, 100);
        // deposit 15% reserve tokens into primary reserve
        reservePool.depositIntoPrimaryReserve(15);
        assertEq(reservePool.neededReserves(), 5);
    }

    function testSetReserveToken() public {
        changePrank(deployer);
        reservePool.setReserveToken(address(reserveToken));
        assertEq(address(reservePool.reserveToken()), address(reserveToken));
    }

    function testSetRiskOracle() public {
        changePrank(deployer);
        reservePool.setRiskOracle(address(riskOracle));
        assertEq(address(reservePool.riskOracle()), address(riskOracle));
    }

    function testRTDWithNoDebt() public {
        changePrank(deployer);
        uint256 rtd = reservePool.RTD();
        assertEq(rtd, 0);
    }

    function testSetTargetRTD() public {
        changePrank(deployer);
        reservePool.setTargetRTD(100 * 1 ether);
        assertEq(reservePool.targetRTD(), 100 * 1 ether);
    }

    function testSetTargetRTDWithNeededReserves() public {
        changePrank(deployer);
        // create 100 supply of credit token
        creditToken.mint(bob, 100);
        // deposit into excess reserve
        reservePool.depositIntoExcessReserve(100);
        // set target RTD to 100%
        reservePool.setTargetRTD(100 * 10e16);
        // check that excess reserve was moved to primary reserve
        assertEq(reservePool.primaryBalance(), 100);
        assertEq(reservePool.excessBalance(), 0);
    }

    function testSetTargetRTDWithPartiallyNeededReserves() public {
        changePrank(deployer);
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
    }
}
