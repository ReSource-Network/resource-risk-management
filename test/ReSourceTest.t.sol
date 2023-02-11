// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "forge-std/Test.sol";

import "../src/RiskManager.sol";
import "../src/ReservePool.sol";
import "../src/RiskOracle.sol";
import "../src/CreditIssuer/ReSourceCreditIssuer.sol";
import "./MockERC20.sol";
import "@resource-stable-credit/StableCredit.sol";
import "@resource-stable-credit/AccessManager.sol";
import "@resource-stable-credit/FeeManager/FeeManager.sol";

contract ReSourceTest is Test {
    address deployer;

    // risk management contracts
    RiskManager public riskManager;
    ReservePool public reservePool;
    RiskOracle public riskOracle;
    ReSourceCreditIssuer public creditIssuer;

    // stable credit network contracts
    StableCredit public stableCredit;
    MockERC20 referenceToken;
    AccessManager public accessManager;
    FeeManager public feeManager;

    function setUpReSourceTest() public {
        deployer = address(1);
        vm.startPrank(deployer);

        // deploy riskManager
        riskManager = new RiskManager();
        riskManager.initialize();
        // deploy reservePool
        reservePool = new ReservePool();
        reservePool.initialize(address(riskManager));
        // deploy riskOracle
        riskOracle = new RiskOracle();
        riskOracle.initialize();
        // deploy creditIssuer
        creditIssuer = new ReSourceCreditIssuer();
        creditIssuer.initialize();

        // set riskManager's reservePool
        riskManager.setReservePool(address(reservePool));
        // deploy mock stable access manager and credit network
        accessManager = new AccessManager();
        accessManager.initialize(new address[](0));
        referenceToken = new MockERC20(1000000 * (10e18), "Reference Token", "REF");
        // deploy stable credit network
        stableCredit = new StableCredit();
        stableCredit.__StableCredit_init(
            address(referenceToken), address(accessManager), address(creditIssuer), "mock", "MOCK"
        );
        //deploy feeManager
        feeManager = new FeeManager();
        feeManager.initialize(address(stableCredit));
        // initialize contract variables
        accessManager.grantOperator(address(stableCredit));
        reservePool.setTargetRTD(address(stableCredit), 200000); // set targetRTD to 20%
        creditIssuer.setPeriodLength(address(stableCredit), 90 days); // set defaultCutoff to 90 days
        creditIssuer.setGracePeriodLength(address(stableCredit), 30 days); // set gracePeriod to 30 days
        creditIssuer.setMinITD(address(stableCredit), 100000); // set max income to debt ratio to 10%
        vm.stopPrank();
    }
}
