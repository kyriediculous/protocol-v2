// // SPDX-FileCopyrightText: 2020 Tenderize <info@tenderize.me>

// // SPDX-License-Identifier: GPL-3.0

// /* See contracts/COMPILERS.md */

pragma solidity ^0.8.0;

// import "@openzeppelin/contracts/utils/math/SafeMath.sol";
// import "../utils/MathUtils.sol";

contract Delegations {

    /**
     @notice Delegation holds the necessary info for delegations to a delegation pool
     */
    struct Delegation {
        uint256 shares; // nominal amount of shares held by the Delegation
        uint256 feeCheckpoint; // amount of fees in the pool after last claim
    }

    /**
     @notice A delegation pool accrues delegator rewards and fees for an orchestrator and handles accounting
     */
    struct Pool {
        uint256 totalShares; // total amount of outstanding shares

        uint256 totalStake; // total amount of tokens held by the EarningsPool
        uint256 fees; // total amount of available fees (claimed or unclaimed, but not withdrawn)

        // mapping of a delegate's address to a Delegation
        mapping (address => Delegation) delegations;
    }

    /**
     * @notice Stake an amount of tokens in the pool, mints an amount of shares representing the nominal amount of tokens staked in return
     * @param _delegator address of the delegator that is staking to the pool
     * @param _amount amount of tokens being staked by the delegator
     */
    function stake(address _delegator, uint256 _amount) public {
        // Delegations.Pool storage _pool;
        // uint256 sharesToMint = tokensToShares(_pool, _amount);
        // mintShares(_pool, _delegator, sharesToMint);
        // _pool.totalStake = _pool.totalStake.add(_amount);
    }

    /**
     * @notice Unstake an amount of tokens from the pool, burns an amount of shares representing the nominal amount of tokens unstaked
     * @param _delegator address of the delegator that is unstaking from the pool
     * @param _amount amount of tokens being unstaked by the delegator
     */
    function unstake(address _delegator, uint256 _amount) public {
        // Delegations.Pool storage  _pool;
        // uint256 sharesToBurn = tokensToShares(_pool, _amount);
        // burnShares(_pool, _delegator, sharesToBurn);
        // _pool.totalStake = _pool.totalStake.sub(_amount);
    }

    /**
     * @notice Add to total stake in the pool
     * @param _amount amount of tokens to add to the total stake
     * @return _stake new total stake in the delegation pool
     */
    function addRewards(uint256 _amount) public returns (uint256 _stake) {
        // Delegations.Pool storage  _pool;
        // stake = _pool.totalStake.add(_amount);
        // _pool.totalStake = stake;
    }

    /**
     * @notice Mint new shares for the pool
     * @param _delegator address of the delegator to mint shares for
     * @param _amount amount of shares to mint
     */
    function mintShares(address _delegator, uint256 _amount) public {
        // Delegations.Pool storage  _pool;
        // _pool.delegations[_delegator].shares = _pool.delegations[_delegator].shares.add(_amount);
        // _pool.totalShares = _pool.totalShares.add(_amount);
    }

    /**
     *@notice Burn existing shares from the pool
     * @param _delegator address of the delegator to burn shares from
     * @param _amount amount of shares to burn
     */
    function burnShares(address _delegator, uint256 _amount) public {
        //  Delegations.Pool storage  _pool;
        // _pool.delegations[_delegator].shares = _pool.delegations[_delegator].shares.sub(_amount);
        // _pool.totalShares = _pool.totalShares.sub(_amount);
    }

    /**
     * @notice Add to total fees in the pool
     * @param _amount amount of fees to add to the pool
     * @return fees new total amount of fees in the delegation pool
     */
    function addFees(uint256 _amount) public returns (uint256 fees) {
        // Delegations.Pool storage  _pool;
        // fees = _pool.fees.add(_amount);
        // _pool.fees = fees;
    }

    /**
     * @notice Claim fees from the delegation pool
     * @dev This only handles state updates to the delegation pool, actual transferring of funds should be handled by the caller
     * @param _delegator address of the delegator to claim fees for
     * @return claimedFees amount of fees claimed
     */
    function claimFees(address _delegator) public returns (uint256 claimedFees) {
        // Delegations.Pool storage  _pool;
        // claimedFees = feesOf(_pool, _delegator);
        // _pool.delegations[_delegator].feeCheckpoint = _pool.fees;
    }

    /**
     * @notice Returns the total stake of a delegator
     * @dev Sum of principal and staking rewards
     * @param _delegator address of the delegator
     * @return _stake of the delegator
     */
    function stakeOf(address _delegator) public view returns (uint256 _stake) {
        // Delegations.Pool storage  _pool;
        // stake = MathUtils.percOf(_pool.totalStake, _pool.delegations[_delegator].shares, _pool.totalShares);
    }

    /**
     * @notice Returns the nominal amount of shares of a delegation pool owned by a delegator
     * @param _delegator address of the delegator
     * @return shares of the delegation pool own by the delegator
     */
    function sharesOf(address _delegator) public view returns (uint256 shares) {
        // Delegations.Pool storage  _pool;
        // shares = _pool.delegations[_delegator].shares;
    }

    /**
     * @notice Returns the amount of claimable fees from a delegation pool for a delegator
     * @param _delegator address of the delegator
     * @return fees claimable from the delegation pool for the delegator
     */
    function feesOf(address _delegator) public view returns (uint256 fees) {
        // Delegations.Pool storage  _pool;
        // Delegation storage delegation = _pool.delegations[_delegator];
        // uint256 feeCheckpoint = delegation.feeCheckpoint;
        // uint256 availableFees = _pool.fees.sub(feeCheckpoint);
        // fees = MathUtils.percOf(availableFees, delegation.shares, _pool.totalShares);
    }

    /**
     * @notice Convert an amount of tokens to the nominal amount of shares it represents in the pool
     * @param _tokens amount of tokens to calculate share amount for
     * @return shares amount of shares that represent the underlying tokens
     */
    function tokensToShares(uint256 _tokens) public view returns (uint256 shares) {
        // Delegations.Pool storage  _pool;
        // uint256 totalStake = _pool.totalStake;
        // uint256 totalShares = _pool.totalShares;

        // if (totalStake == 0) {
        //     return 0;
        // }

        // if (totalShares == 0) {
        //     return _tokens;
        // }

        // shares = MathUtils.percOf(_tokens, totalShares, _pool.totalStake);
    }

    /**
     * @notice Convert an amount of shares to the amount of tokens in the delegation pool it represents
     * @param _shares amount of shares to calculate token amount for
     * @return tokens amount of tokens represented by the shares
     */
    function sharesToTokens(uint256 _shares) public view returns (uint256 tokens) {
        // Delegations.Pool storage  _pool;
        // uint256 totalShares = _pool.totalShares;
        // if ( totalShares == 0) {
        //     return 0;
        // }

        // tokens = MathUtils.percOf(_pool.totalStake, _shares, _pool.totalShares);
    }
}