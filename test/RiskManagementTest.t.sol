// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "forge-std/Test.sol";

import "../contracts/AssurancePool.sol";
import "../contracts/RiskOracle.sol";
import "./MockERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@uniswap/v3-periphery/contracts/lens/Quoter.sol";

contract RiskManagementTest is Test {
    address alice;
    address bob;
    address deployer;

    AssurancePool public assurancePool;
    RiskOracle public riskOracle;
    ERC20 public reserveToken;
    MockERC20 public creditToken;

    // STATIC VARIABLES
    address USDCAddress = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address USDCWhale = 0x78605Df79524164911C144801f41e9811B7DB73D;
    address WETHAddress = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address UniSwapRouterAddress = 0xE592427A0AEce92De3Edee1F18E0157C05861564;
    Quoter quoter = Quoter(0xb27308f9F90D607463bb33eA1BeBb41C27CE5AB6);

    function setUpReSourceTest() public {
        alice = address(2);
        bob = address(3);
        vm.deal(alice, 100 ether);
        vm.deal(bob, 100 ether);
        deployer = address(1);
        vm.startPrank(deployer);

        // deploy reserve token
        reserveToken = ERC20(USDCAddress);
        // deploy credit token
        creditToken = new MockERC20(0, "Credit Token", "CRD");
        // deploy riskOracle
        riskOracle = new RiskOracle();
        riskOracle.initialize(deployer);
        // deploy assurancePool
        assurancePool = new AssurancePool();
        assurancePool.initialize(
            address(creditToken),
            address(reserveToken),
            deployer,
            address(riskOracle),
            UniSwapRouterAddress
        );
        assurancePool.setTargetRTD(20e16); // set targetRTD to 20%
        riskOracle.setBaseFeeRate(address(assurancePool), 5e16); // set base fee rate to 5%
        changePrank(USDCWhale);
        // send 100k USDC to deployer
        reserveToken.transfer(deployer, 100000e6);
        vm.stopPrank();
    }
}
