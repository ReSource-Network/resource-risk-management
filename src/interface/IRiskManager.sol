// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IReservePool.sol";

interface IRiskManager {
    function reservePool() external view returns (IReservePool);
}
