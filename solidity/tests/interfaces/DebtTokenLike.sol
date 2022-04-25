// SPDX-License-Identifier: UNLICENSED
// !! THIS FILE WAS AUTOGENERATED BY abi-to-sol v0.5.2. SEE SOURCE BELOW. !!
pragma solidity >=0.8.4 <0.9.0;

interface DebtTokenLike {
  event Approval(address indexed owner, address indexed spender, uint256 value);
  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
  event Transfer(address indexed from, address indexed to, uint256 value);

  function allowance(address owner, address spender) external view returns (uint256);

  function approve(address spender, uint256 amount) external returns (bool);

  function balanceOf(address account) external view returns (uint256);

  function burn(address from, uint256 amount) external;

  function decimals() external view returns (uint8);

  function decreaseAllowance(address spender, uint256 subtractedValue) external returns (bool);

  function increaseAllowance(address spender, uint256 addedValue) external returns (bool);

  function initialize(
    string memory _name,
    string memory _symbol,
    uint8 _decimals,
    address _timelock
  ) external;

  function mint(address to, uint256 amount) external;

  function name() external view returns (string memory);

  function okHolders(address) external view returns (bool);

  function owner() external view returns (address);

  function renounceOwnership() external;

  function setOkHolders(address[] memory _okHolders, bool _isOk) external;

  function symbol() external view returns (string memory);

  function totalSupply() external view returns (uint256);

  function transfer(address to, uint256 amount) external returns (bool);

  function transferFrom(
    address from,
    address to,
    uint256 amount
  ) external returns (bool);

  function transferOwnership(address newOwner) external;
}