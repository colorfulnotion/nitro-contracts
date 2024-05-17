// SPDX-License-Identifier: Apache-2.0
pragma solidity >=0.4.21 <0.9.0;

interface ArbBabylon {
    function GetPublicRandomness(bytes calldata fpBtcPk, uint64 blockHeight) external view returns (bytes memory);
    function SetPublicRandomness(bytes calldata fpBtcPk, uint64 blockHeight, bytes calldata pubRand, bytes calldata sig) external returns (uint64);
    event PubRandListCommitted(address indexed caller);

    function GetFinalitySig(bytes calldata fpBtcPk, uint64 blockHeight) external view returns (bytes memory);
    function SetFinalitySig(bytes calldata fpBtcPk, uint64 blockHeight, bytes calldata blockHash, bytes calldata finalitySig) external returns (uint64);
    event FinalitySigAdded(address indexed caller);

    function GetBLSKey(bytes calldata fpBtcPk) external view returns (bytes memory);
    function SetBLSKey(bytes calldata fpBtcPk, bytes calldata blsPublicKey, bytes calldata sig) external returns (uint64);
    event BLSKeyRegistered(address indexed caller);
}
