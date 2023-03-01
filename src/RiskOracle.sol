// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

// TODO: implement
contract RiskOracle is OwnableUpgradeable {
    function initialize() external virtual initializer {
        __Ownable_init();
    }
}
