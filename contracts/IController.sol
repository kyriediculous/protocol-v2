pragma solidity ^0.8.0;

interface IController {
    event SetContractInfo(bytes32 id, address contractAddress, bytes20 gitCommitHash);

    function setContractInfo(
        bytes32 _id,
        address _contractAddress,
        bytes20 _gitCommitHash
    ) external;

    function updateController(bytes32 _id, address _controller) external;

    function getContract(bytes32 _id) external view returns (address);
}