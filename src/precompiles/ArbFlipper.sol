// SPDX-License-Identifier: Apache-2.0
pragma solidity >=0.4.21 <0.9.0;

interface ArbFlipper {
    // Emit event when Flip is called
    event Flipped(address indexed caller);

    event Hi(address indexed caller);

    function flip() external returns (string memory);

    function getNumber() external view returns (uint64);

    function setNumber(uint64 newNumber) external returns (uint64);

    function getFlipState() external view returns (uint64);

    function getFlipCount() external view returns (uint64);
}
