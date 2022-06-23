// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4 <0.9.0;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import { AIP8AUSDStakingBase, AIP8AUSDStakingLike, console, UserInfo } from "./AIP8AUSDStakingBase.sol";
import { IFairLaunch } from "../../../contracts/8.15/interfaces/IFairLaunch.sol";
import { mocking } from "../../utils/mocking.sol";

// solhint-disable func-name-mixedcase
// solhint-disable contract-name-camelcase
contract AIP8AUSDStaking_TestLock is AIP8AUSDStakingBase {
  using mocking for *;

  function test_lock_aliceLockAlone_shouldSuccess() external {
    uint256 _expectedStakingAmount = 1 ether;
    uint256 _expectedLockUntil = block.timestamp + WEEK;

    _lockFor(_ALICE, _expectedStakingAmount, _expectedLockUntil); // BLOCK IS NOT MINED HERE

    UserInfo memory _userInfo = aip8AUSDStaking.userInfo(_ALICE);
    assertEq(_userInfo.stakingAmount, _expectedStakingAmount);
    assertEq(_userInfo.lockUntil, _expectedLockUntil);
    assertEq(_userInfo.alpacaRewardDebt, 0);

    (uint256 _fairlaunchAmount, , , address _fundedBy) = IFairLaunch(fairlaunchAddress).userInfo(
      pid,
      address(aip8AUSDStaking)
    );
    assertEq(_expectedStakingAmount, _fairlaunchAmount);
    assertEq(address(aip8AUSDStaking), _fundedBy);
  }

  function test_lock_aliceAndBobLock_shouldSuccess() external {
    uint256 _expectedStakingAmountAlice = 1 ether;
    uint256 _expectedLockUntilAlice = block.timestamp + WEEK;
    uint256 _expectedStakingAmountBob = 2 ether;
    uint256 _expectedLockUntilBob = block.timestamp + (WEEK * 2);

    _lockFor(_ALICE, _expectedStakingAmountAlice, _expectedLockUntilAlice); // BLOCK IS NOT MINED HERE
    _lockFor(_BOB, _expectedStakingAmountBob, _expectedLockUntilBob); // BLOCK IS NOT MINED HERE

    UserInfo memory _userInfoAlice = aip8AUSDStaking.userInfo(_ALICE);
    assertEq(_userInfoAlice.stakingAmount, _expectedStakingAmountAlice, "Alice stakingAmount");
    assertEq(_userInfoAlice.lockUntil, _expectedLockUntilAlice, "Alice lockUntil");
    assertEq(_userInfoAlice.alpacaRewardDebt, 0, "Alice alpacaRewardDebt");

    UserInfo memory _userInfoBob = aip8AUSDStaking.userInfo(_BOB);
    assertEq(_userInfoBob.stakingAmount, _expectedStakingAmountBob, "Bob stakingAmount");
    assertEq(_userInfoBob.lockUntil, _expectedLockUntilBob, "Bob lockUntil");
    assertEq(_userInfoBob.alpacaRewardDebt, 0, "Bob alpacaRewardDebt");

    (uint256 _fairlaunchAmount, , , address _fundedBy) = IFairLaunch(fairlaunchAddress).userInfo(
      pid,
      address(aip8AUSDStaking)
    );
    assertEq(_expectedStakingAmountAlice + _expectedStakingAmountBob, _fairlaunchAmount);
    assertEq(address(aip8AUSDStaking), _fundedBy);
  }

  function test_lock_aliceAndBobLock_withGapTimeBetween_shouldSuccess() external {
    uint256 _expectedStakingAmountAlice = 1 ether;
    uint256 _expectedLockUntilAlice = block.timestamp + WEEK;
    uint256 _expectedStakingAmountBob = 2 ether;
    uint256 _expectedLockUntilBob = block.timestamp + (WEEK * 2);

    _lockFor(_ALICE, _expectedStakingAmountAlice, _expectedLockUntilAlice); // BLOCK IS NOT MINED HERE
    vm.roll(block.number + 1000);
    _lockFor(_BOB, _expectedStakingAmountBob, _expectedLockUntilBob);

    UserInfo memory _userInfoAlice = aip8AUSDStaking.userInfo(_ALICE);
    assertEq(_userInfoAlice.stakingAmount, _expectedStakingAmountAlice, "Alice stakingAmount");
    assertEq(_userInfoAlice.lockUntil, _expectedLockUntilAlice, "Alice lockUntil");
    assertEq(_userInfoAlice.alpacaRewardDebt, 0, "Alice alpacaRewardDebt");

    UserInfo memory _userInfoBob = aip8AUSDStaking.userInfo(_BOB);
    assertEq(_userInfoBob.stakingAmount, _expectedStakingAmountBob, "Bob stakingAmount");
    assertEq(_userInfoBob.lockUntil, _expectedLockUntilBob, "Bob lockUntil");

    // pendingAlpaca (since Alice lock) = 42196193000000 (from console.log)
    // totalStakingTokenAmount (before Bob lock) = 1e18
    // previousAccAlpacaPerShare = 0
    // accAlpacaPerShare = previousAccAlpacaPerShare + ((pendingAlpaca * 1e12) / totalStakingTokenAmount)
    //                   = 0 + ((42196193000000 * 1e12) / 1e18)
    //                   = 42196193
    // rewardDebt = stakingAmount * accAlpacaPerShare / 1e12
    //            = 2e18 * 42196193 / 1e12
    //            = 84392386000000
    assertEq(_userInfoBob.alpacaRewardDebt, 84392386000000, "Bob alpacaRewardDebt");

    (uint256 _fairlaunchAmount, , , address _fundedBy) = IFairLaunch(fairlaunchAddress).userInfo(
      pid,
      address(aip8AUSDStaking)
    );
    assertEq(_expectedStakingAmountAlice + _expectedStakingAmountBob, _fairlaunchAmount);
    assertEq(address(aip8AUSDStaking), _fundedBy);
  }
}
