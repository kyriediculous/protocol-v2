pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../zeppelin/Ownable.sol";

interface ILivepeerToken is IERC20 {
    function mint(address _to, uint256 _amount) external returns (bool);

    function burn(uint256 _amount) external;
}
