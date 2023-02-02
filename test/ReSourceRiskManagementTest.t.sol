// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.13;

import "forge-std/Test.sol";

import "../src/RiskManager.sol";
import "../src/ReservePool.sol";
import "../src/RiskOracle.sol";
import "./MockERC20.sol";
import "@resource-stable-credit/StableCredit.sol";
import "@resource-stable-credit/AccessManager.sol";

contract ReSourceRiskManagementTest is Test {
    address deployer;

    // risk management contracts
    RiskManager public riskManager;
    ReservePool public reservePool;
    RiskOracle public riskOracle;

    // stable credit network contracts
    StableCredit public stableCredit;
    AccessManager public accessManager;

    function setUpRiskManagement() public {
        deployer = address(1);
        vm.startPrank(deployer);

        // deploy riskManager, reservePool, riskOracle, and stableCredit
        riskManager = new RiskManager();
        riskManager.initialize();
        reservePool = new ReservePool();
        reservePool.initialize(address(riskManager));

        // TODO: riskOracle
        // riskOracle = new RiskOracle();
        // riskOracle.initialize();

        // set riskManager's reservePool
        riskManager.setReservePool(address(reservePool));
        // deploy mock stable access manager and credit network
        accessManager = new AccessManager();
        accessManager.initialize(new address[](0));
        MockERC20 referenceToken = new MockERC20(1000000000, "Reference Token", "REF");
        // deploy stable credit network
        stableCredit = new StableCredit();
        stableCredit.__StableCredit_init(
            address(referenceToken), address(accessManager), "mock", "MOCK"
        );
        // initialize contract variables
        // stableCredit.set
        accessManager.grantOperator(address(stableCredit));
        reservePool.setTargetRTD(address(stableCredit), 200000); // set targetRTD to 20%
        vm.stopPrank();
    }
}
