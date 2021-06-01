// // SPDX-FileCopyrightText: 2020 Tenderize <info@tenderize.me>

// // SPDX-License-Identifier: GPL-3.0

// /* See contracts/COMPILERS.md */

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "../utils/MathUtils.sol";



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

library Delegations{
    using SafeMath for uint256;

    /**
     @notice Delegation
     */
    struct Delegation {
        uint256 shares; // nominal amount of shares held by the Delegation
        uint256 feeCheckpoint; // amount of fees in the pool after last claim
    }

    /**
     @notice Pool
     */
    struct Pool {
        uint256 totalShares; // total amount of outstanding shares

        uint256 totalStake; // total amount of tokens held by the EarningsPool
        uint256 fees; // total amount of available fees (claimed or unclaimed, but not withdrawn)

        // mapping of a delegate's address to a Delegation
        mapping (address => Delegation) delegations;
    }

    // Staking
    /**
     * @notice Stake an amount of tokens in the pool, mints an amount of shares representing the nominal amount of tokens staked in return
     * @param _pool storage pointer to the delegation pool
     * @param _delegator address of the delegator that is staking to the pool
     * @param _amount amount of tokens being staked by the delegator
     */
    function stake(Pool storage _pool, address _delegator, uint256 _amount) internal {
        uint256 sharesToMint = tokensToShares(_pool, _amount);
        mintShares(_pool, _delegator, sharesToMint);
        _pool.totalStake = _pool.totalStake.add(_amount);
    }

    /**
     * @notice Unstake an amount of tokens from the pool, burns an amount of shares representing the nominal amount of tokens unstaked
     * @param _pool storage pointer to the delegation pool
     * @param _delegator address of the delegator that is unstaking from the pool
     * @param _amount amount of tokens being unstaked by the delegator
     */
    function unstake(Pool storage _pool, address _delegator, uint256 _amount) internal {
        uint256 sharesToBurn = tokensToShares(_pool, _amount);
        burnShares(_pool, _delegator, sharesToBurn);
        _pool.totalStake = _pool.totalStake.sub(_amount);
    }

    /**
     * @notice Add to total stake in the pool
     * @param _pool storage pointer to the delegation pool
     * @param _amount amount of tokens to add to the total stake
     * @return stake new total stake in the delegation pool
     */
    function addRewards(Pool storage _pool, uint256 _amount) internal returns (uint256 stake) {
        stake = _pool.totalStake.add(_amount);
        _pool.totalStake = stake;
    }

    // Cap Table Management
    /**
     * @notice Mint new shares for the pool
     * @param _pool storage pointer to the delegation pool
     * @param _delegator address of the delegator to mint shares for
     * @param _amount amount of shares to mint
     */
    function mintShares(Pool storage _pool, address _delegator, uint256 _amount) internal {
        _pool.delegations[_delegator].shares = _pool.delegations[_delegator].shares.add(_amount);
        _pool.totalShares = _pool.totalShares.add(_amount);
    }

    /**
     *@notice Burn existing shares from the pool
     * @param _pool storage pointer to the delegation pool
     * @param _delegator address of the delegator to burn shares from
     * @param _amount amount of shares to burn
     */
    function burnShares(Pool storage _pool, address _delegator, uint256 _amount) internal {
        _pool.delegations[_delegator].shares = _pool.delegations[_delegator].shares.sub(_amount);
        _pool.totalShares = _pool.totalShares.sub(_amount);
    }

    // Fees
    /**
     * @notice Add to total fees in the pool
     * @param _pool storage pointer to the delegation pool
     * @param _amount amount of fees to add to the pool
     * @return fees new total amount of fees in the delegation pool
     */
    function addFees(Pool storage _pool, uint256 _amount) internal returns (uint256 fees) {
        fees = _pool.fees.add(_amount);
        _pool.fees = fees;
    }

    /**
     * @notice Claim fees from the delegation pool
     * @dev This only handles state updates to the delegation pool, actual transferring of funds should be handled by the caller
     * @param _pool storage pointer to the delegation pool
     * @param _delegator address of the delegator to claim fees for
     * @return claimedFees amount of fees claimed
     */
    function claimFees(Pool storage _pool, address _delegator) internal returns (uint256 claimedFees) {
        claimedFees = feesOf(_pool, _delegator);
        _pool.delegations[_delegator].feeCheckpoint = _pool.fees;
    }


    // Getters
    /**
     * @notice Returns the total stake of a delegator
     * @dev Sum of principal and staking rewards
     * @param _pool storage pointer to the delegation pool
     * @param _delegator address of the delegator
     * @return stake of the delegator
     */
    function stakeOf(Pool storage _pool, address _delegator) internal view returns (uint256 stake) {
        stake = MathUtils.percOf(_pool.totalStake, _pool.delegations[_delegator].shares, _pool.totalShares);
    }

    /**
     * @notice Returns the nominal amount of shares of a delegation pool owned by a delegator
     * @param _pool storage pointer to the delegation pool
     * @param _delegator address of the delegator
     * @return shares of the delegation pool own by the delegator
     */
    function sharesOf(Pool storage _pool, address _delegator) internal view returns (uint256 shares) {
        shares = _pool.delegations[_delegator].shares;
    }

    /**
     * @notice Returns the amount of claimable fees from a delegation pool for a delegator
     * @param _pool storage pointer to the delegation pool
     * @param _delegator address of the delegator
     * @return fees claimable from the delegation pool for the delegator
     */
    function feesOf(Pool storage _pool, address _delegator) internal view returns (uint256 fees) {
        Delegation storage delegation = _pool.delegations[_delegator];
        uint256 feeCheckpoint = delegation.feeCheckpoint;
        uint256 availableFees = _pool.fees.sub(feeCheckpoint);
        fees = MathUtils.percOf(availableFees, delegation.shares, _pool.totalShares);
    }

    // Helpers
    /**
     * @notice Convert an amount of tokens to the nominal amount of shares it represents in the pool
     * @param _pool storage pointer to the delegation pool
     * @param _tokens amount of tokens to calculate share amount for
     * @return shares amount of shares that represent the underlying tokens
     */
    function tokensToShares(Pool storage _pool, uint256 _tokens) internal view returns (uint256 shares) {
        shares = MathUtils.percOf(_tokens, _pool.totalShares, _pool.totalStake);
    }

    /**
     * @notice Convert an amount of shares to the amount of tokens in the delegation pool it represents
     * @param _pool storage pointer to the delegation pool
     * @param _shares amount of shares to calculate token amount for
     * @return tokens amount of tokens represented by the shares
     */
    function sharesToTokens(Pool storage _pool, uint256 _shares) internal view returns (uint256 tokens) {
        tokens = MathUtils.percOf(_pool.totalStake, _shares, _pool.totalShares);
    }
}