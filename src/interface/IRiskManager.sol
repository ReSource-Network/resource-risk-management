// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IRiskManager {
    function reimburseMember(address network, address member, uint256 amount) external;

    function depositPayment(address network, uint256 amount) external;

    function depositFees(address network, uint256 amount) external;

    function reservePool() external view returns (address);

    function baseFeeRate(address network) external view returns (uint256);
}
