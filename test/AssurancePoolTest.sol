// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./RiskManagementTest.t.sol";

contract AssurancePoolTest is RiskManagementTest {
    function setUp() public {
        setUpReSourceTest();
        changePrank(deployer);
        reserveToken.approve(address(assurancePool), type(uint256).max);
    }

    // deposit into primary reserve updates total reserve and primary reserve
    function testDepositIntoPrimaryReserve() public {
        // deposit reserve updates reserve in reserve pool
        changePrank(deployer);
        uint256 amount = 100;
        // deposit into primary reserve
        assurancePool.depositIntoPrimaryReserve(amount);
        // check total reserve
        assertEq(assurancePool.reserveBalance(), amount);
        // check primary reserve
        assertEq(assurancePool.primaryBalance(), amount);
    }

    // deposit into peripheral reserve updates total reserve and peripheral reserve
    function testDepositIntoPeripheralReserve() public {
        changePrank(deployer);
        uint256 amount = 100;
        // deposit into peripheral reserve
        assurancePool.depositIntoPeripheralReserve(amount);
        // check total reserve
        assertEq(assurancePool.reserveBalance(), amount);
        // check peripheral reserve
        assertEq(assurancePool.peripheralBalance(), amount);
    }

    // deposit needed reserves updates excess pool when RTD is above target
    function testSettleReserveWithHighRTD() public {
        changePrank(deployer);
        uint256 amount = 100 ether;
        assertEq(assurancePool.excessBalance(), 0);
        // TODO: send x eth to deployer
        assurancePool.settleReserves();
        // check excess reserve
        assertEq(assurancePool.excessBalance(), amount);
    }

    // deposit fees updates reserve when RTD is below target
    function testSettleReserveWithWithLowRTD() public {
        // deposit fees updates fees in reserve pool
        changePrank(alice);
        // create 100 supply of credit token
        creditToken.mint(bob, 100 ether);
        changePrank(deployer);
        assertEq(assurancePool.excessBalance(), 0);
        // TODO: send x eth to deployer
        assurancePool.settleReserves();
        assertEq(assurancePool.reserveBalance(), 20);
        assertEq(assurancePool.excessBalance(), 80);
    }

    function testUpdateBaseFeeRate() public {
        // update base fee rate
        changePrank(deployer);
        riskOracle.setBaseFeeRate(address(assurancePool), 10000);
        assertEq(riskOracle.baseFeeRate(address(assurancePool)), 10000);
    }

    function testWithdraw() public {
        // withdraw from reserve pool
        changePrank(deployer);
        uint256 deployerBalance = reserveToken.balanceOf(deployer);
        uint256 amount = 100e6;
        assurancePool.depositIntoExcessReserve(amount);
        assertEq(reserveToken.balanceOf(deployer), deployerBalance - amount);
        assertEq(assurancePool.excessBalance(), amount);
        assurancePool.withdraw(amount);
        assertEq(reserveToken.balanceOf(deployer), deployerBalance);
        assertEq(assurancePool.excessBalance(), 0);
    }

    function testReimburseAccountWithPrimaryReserve() public {
        changePrank(deployer);
        // deposit into primary reserve
        uint256 amount = 100 * 10e6;
        assurancePool.depositIntoPrimaryReserve(amount);
        changePrank(address(creditToken));
        assurancePool.reimburseAccount(bob, 10 * 10e6);
        assertEq(assurancePool.primaryBalance(), 90 * 10e6);
        assertEq(reserveToken.balanceOf(bob), 10 * 10e6);
    }

    function testReimburseAccountWithPrimaryAndPeripheralReserve() public {
        changePrank(deployer);
        // deposit into primary reserve
        uint256 amount = 100 * 10e6;
        assurancePool.depositIntoPrimaryReserve(amount);
        // deposit into peripheral reserve
        assurancePool.depositIntoPeripheralReserve(amount);
        changePrank(address(creditToken));
        assurancePool.reimburseAccount(bob, 10 * 10e6);
        assertEq(assurancePool.primaryBalance(), 100 * 10e6);
        assertEq(assurancePool.peripheralBalance(), 90 * 10e6);
        assertEq(reserveToken.balanceOf(bob), 10 * 10e6);
    }

    function testConvertCreditTokenToReserveToken() public {
        assertEq(
            assurancePool.convertCreditTokenToReserveToken(
                100 * (10 ** IERC20Metadata(address(creditToken)).decimals())
            ),
            100 * (10 ** IERC20Metadata(address(reserveToken)).decimals())
        );
    }

    function testConvertReserveTokenToCreditToken() public {
        assertEq(
            assurancePool.convertReserveTokenToCreditToken(
                100 * (10 ** IERC20Metadata(address(reserveToken)).decimals())
            ),
            100 * (10 ** IERC20Metadata(address(creditToken)).decimals())
        );
    }

    function testReimburseAccountWithInsufficientReserve() public {
        changePrank(deployer);
        // deposit into primary reserve
        uint256 amount = 25 * 10e6;
        assurancePool.depositIntoPrimaryReserve(amount);
        // deposit into peripheral reserve
        assurancePool.depositIntoPeripheralReserve(amount);
        changePrank(address(creditToken));
        assurancePool.reimburseAccount(bob, 60 * 10e6);
        assertEq(assurancePool.primaryBalance(), 0);
        assertEq(assurancePool.peripheralBalance(), 0);
        assertEq(reserveToken.balanceOf(bob), 50 * 10e6);
    }

    function testNeededReserves() public {
        changePrank(deployer);
        // create 100 supply of credit token
        creditToken.mint(bob, 100 ether);
        // deposit 15% reserve tokens into primary reserve
        assurancePool.depositIntoPrimaryReserve(15e6);
        assertEq(assurancePool.neededReserves(), 5e6);
    }

    function testSetReserveToken() public {
        changePrank(deployer);
        assurancePool.setReserveToken(address(reserveToken));
        assertEq(address(assurancePool.reserveToken()), address(reserveToken));
    }

    function testSetRiskOracle() public {
        changePrank(deployer);
        assurancePool.setRiskOracle(address(riskOracle));
        assertEq(address(assurancePool.riskOracle()), address(riskOracle));
    }

    function testRTDWithNoDebt() public {
        changePrank(deployer);
        uint256 rtd = assurancePool.RTD();
        assertEq(rtd, 0);
    }

    function testSetTargetRTD() public {
        changePrank(deployer);
        assurancePool.setTargetRTD(100 * 1 ether);
        assertEq(assurancePool.targetRTD(), 100 * 1 ether);
    }

    function testSetTargetRTDWithNeededReserves() public {
        changePrank(deployer);
        // create 100 supply of credit token
        creditToken.mint(bob, 100 ether);
        // deposit into excess reserve
        assurancePool.depositIntoExcessReserve(100e6);
        // set target RTD to 100%
        assurancePool.setTargetRTD(1000e16);
        // check that excess reserve was moved to primary reserve
        assertEq(assurancePool.primaryBalance(), 100e6);
        assertEq(assurancePool.excessBalance(), 0);
    }

    function testSetTargetRTDWithPartiallyNeededReserves() public {
        changePrank(deployer);
        // create 100 supply of credit token
        creditToken.mint(bob, 100 ether);
        // deposit 15% reserve tokens into primary reserve
        assurancePool.depositIntoPrimaryReserve(15e6);
        // deposit into excess reserve
        assurancePool.depositIntoExcessReserve(100e6);
        // change target RTD to 25%
        assurancePool.setTargetRTD(25e16);
        // check that excess reserve was moved to primary reserve
        assertEq(assurancePool.primaryBalance(), 25e6);
        assertEq(assurancePool.excessBalance(), 90e6);
    }
}
