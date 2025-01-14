// SPDX-License-Identifier: MIT
/**
  ∩~~~~∩ 
  ξ ･×･ ξ 
  ξ　~　ξ 
  ξ　　 ξ 
  ξ　　 “~～~～〇 
  ξ　　　　　　 ξ 
  ξ ξ ξ~～~ξ ξ ξ 
　 ξ_ξξ_ξ　ξ_ξξ_ξ
Alpaca Fin Corporation
*/

pragma solidity 0.8.13;

import "../interfaces/MockErc20Like.sol";
import { FakeDeltaWorker } from "./FakeDeltaWorker.sol";
import { FakeVault } from "./FakeVault.sol";
import { console } from "../utils/console.sol";

/// @title FakeDeltaNeutralRepurchaseExecutor : A fake executor used for manipulating underlying LYF position
contract FakeDeltaNeutralRepurchaseExecutor {
  FakeDeltaWorker public stableWorker;
  FakeDeltaWorker public assetWorker;

  FakeVault public stableVault;
  FakeVault public assetVault;

  uint256 public stableDebt;
  uint256 public assetDebt;

  uint256 public lpPrice;

  constructor(
    address _stableVault,
    address _assetVault,
    address _stableWorker,
    address _assetWorker,
    uint256 _lpPrice
  ) {
    stableWorker = FakeDeltaWorker(_stableWorker);
    assetWorker = FakeDeltaWorker(_assetWorker);
    stableVault = FakeVault(_stableVault);
    assetVault = FakeVault(_assetVault);
    lpPrice = _lpPrice;
  }

  function setExecutionValue(uint256 _stableDebt, uint256 _assetDebt) external {
    stableDebt = _stableDebt;
    assetDebt = _assetDebt;
  }

  function exec(
    bytes memory /*_data*/
  ) external {
    stableVault.setDebt(stableDebt, stableDebt);
    assetVault.setDebt(assetDebt, assetDebt);
  }
}
