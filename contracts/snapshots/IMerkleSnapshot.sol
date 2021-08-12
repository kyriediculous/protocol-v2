pragma solidity ^0.8.0;

contract IMerkleSnapshot {
    function verify(
        bytes32 _id,
        bytes32[] calldata _proof,
        bytes32 _leaf
    ) external view returns (bool);
}
