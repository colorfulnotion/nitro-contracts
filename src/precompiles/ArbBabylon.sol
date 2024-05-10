// SPDX-License-Identifier: MIT
pragma solidity >=0.4.21 <0.9.0;

interface ArbBabylon {
    function commitPubRandList( bytes memory fpBtcPk, uint64 blockHeight, bytes memory pubRand, bytes memory sig) external returns (bool);
    event PubRandListCommitted(bool success);

    function addFinalitySig(bytes memory fpBtcPk, uint64 blockHeight, bytes memory secRand, bytes memory sig) external returns (bool);
    event FinalitySigAdded(bool success);

    function registerBLSKey(bytes memory fpBtcPk, bytes calldata bls_public_key, bytes memory sig) external  returns (bool);
    event BLSAdded(bool success);
}
