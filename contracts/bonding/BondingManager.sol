// // SPDX-FileCopyrightText: 2021 Livepeer <nico@livepeer.org>

// // SPDX-License-Identifier: GPL-3.0

// /* See contracts/COMPILERS.md */

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "../utils/MathUtils.sol";
import "./Delegations.sol";


// Keep BondingManager as stateless as possible
// A lot of state that improves UX can be rebuilt through indexing events instead. Requires archive node access.
// To sync the Eth chain from the start to rebuild the event log requires a relative large set of highly distributed archive nodes.

contract BondingManager {
    using SafeMath for uint256;
    using Delegations for Delegations.Pool;

    struct Orchestrator {
        // Commission accounting
        uint256 rewardShare; // % of reward shared with delegations
        uint256 feeShare; // % of fees shared with delegations
        uint256 rewardCommissions; // reward earned from commission (not shared with delegators)
        uint256 feeCommissions; // fees earned from commission (not shared with delegators)

        // Delegation Pool
        Delegations.Pool delegationPool;
    }

    struct Delegator {
        address orchestrator;
    }

    // Represents an amount of tokens that are being unbonded
    struct UnbondingLock {
        uint256 amount;              // Amount of tokens being unbonded
        uint256 withdrawRound;       // Round at which unbonding period is over and tokens can be withdrawn
    }

    mapping (address => Orchestrator) orchestrators;
    mapping (address => Delegator) delegators;

    mapping(bytes32 => UnbondingLock) unbondingLocks;

    function updateOrchestratorWithRewards(address _orchestrator, uint256 _rewards) internal {
        Orchestrator storage orch = orchestrators[_orchestrator];

        uint256 rewardShare = MathUtils.percOf(_rewards, orch.rewardShare);

        orch.rewardCommissions = _rewards.sub(rewardShare);
        orch.delegationPool.addRewards(rewardShare);
    }

    function updateOrchestratorWithFees(address _orchestrator, uint256 _fees) internal {
        Orchestrator storage orch = orchestrators[_orchestrator];

        uint256 feeShare = MathUtils.percOf(_fees, orch.feeShare);

        orch.feeCommissions = _fees.sub(feeShare);
        orch.delegationPool.addFees(feeShare);
    }

    function stakeOf(address _of) public view returns (uint256 stake) {
        address delegate = delegators[_of].orchestrator;
        Orchestrator storage orch = orchestrators[delegate];
        uint256 delegatorStake = orch.delegationPool.stakeOf(_of);
        uint256 orchRewardCommissions = orch.rewardCommissions;
        stake = delegatorStake.add(orchRewardCommissions);
    }

    function feesOf(address _of) public view returns (uint256 fees) {
        address delegate = delegators[_of].orchestrator;
        Orchestrator storage orch = orchestrators[delegate];
        uint256 delegatorFees = orch.delegationPool.feesOf(_of);
        uint256 orchFeeCommissions = orch.feeCommissions;
        fees = delegatorFees.add(orchFeeCommissions);
    }

    function claimFees(address payable _for) internal {
        address delegate = delegators[_for].orchestrator;
        Orchestrator storage orch = orchestrators[delegate];
        uint256 fees = orch.delegationPool.claimFees(_for);
        if (_for == delegate) {
            fees = fees.add(orch.feeCommissions);
        }
        _for.transfer(fees);
    }

    function bond(address _orchestrator, address payable _delegator, uint256 _amount) internal {
        // Claim any outstanding fees
        claimFees(_delegator);

        address currentDelegate = delegators[_delegator].orchestrator;

        uint256 totalToStake = _amount;

        // If already bonded unstake from old orchestrator's delegation pool
        if (currentDelegate != address(0) /* TODO: make constant */ ) {
            Delegations.Pool storage oldPool = orchestrators[currentDelegate].delegationPool;
            uint256 currentStake = oldPool.stakeOf(_delegator);
            oldPool.unstake(_delegator, currentStake);
            totalToStake = totalToStake.add(currentStake);
        }

        // Bond total to stake to new orchestrator
        Delegations.Pool storage newPool = orchestrators[_orchestrator].delegationPool;
        newPool.stake(_delegator, totalToStake);
    }

    function unbond(address payable _delegator, uint256 _amount) internal {
        // Claim any outstanding fees
        claimFees(_delegator);

        address delegate = delegators[_delegator].orchestrator;

        uint256 amount = _amount;

        // If the delegator is an orchestrator, draw from commission first
        if (_delegator == delegate ) {
            Orchestrator storage orch = orchestrators[delegate];
            uint256 rewardCommissions = orch.rewardCommissions;
            uint256 fromCommission = MathUtils.min(rewardCommissions, _amount);
            orch.rewardCommissions = rewardCommissions.sub(fromCommission);
            amount = amount.sub(fromCommission);
        }

        if (amount > 0) {
            Delegations.Pool storage pool = orchestrators[delegate].delegationPool;
            pool.unstake(_delegator, amount);
        }

        // Create unbonding lock for _amount
        // TODO: deterministic ID or disallow multiple unstakes in same block
        bytes32 id = keccak256(abi.encodePacked(_delegator, _amount, block.number));
        unbondingLocks[id] = UnbondingLock({
            amount: _amount,
            withdrawRound: 0 // TODO: Fix value to real block number or round
        });
    }
}