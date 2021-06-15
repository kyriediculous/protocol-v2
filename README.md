# `Delegations`

## Usage

### Installation

This repository uses yarn as a dependency manager. Install project dependencies by running

```
yarn
```

### Compile

Compile the contracts

```
yarn run compile
```

## Overview

`Delegations` is a Solidity library that handles accounting logic for a stake based protocol whereby users can stake tokens and earn rewards in that tokens as well as fees in another token or ETH.

The implementation details and actual handling of funds transfer is left to the implementer of the library so the library is token standard agnostic.

### Share-based accounting

The library used **share-based accounting** whereby a nominal amount of shares represent an intrinsic amount of stake (including rewards) and protocol fees. Meaning that while the amount of shares a user holds can remain unchanged, the amount of stake and fees it represent can fluctuate as rewards/fees are earned or the delegate's stake is slashed.

The conversion between token amounts and share amount is done using the share price which is expressed as `totalStake / totalShares`. Since staking rewards can increase the stake without increasing the total amount of shares this ratio can diverge away from 1.

### Cumulative Fee Factor

Tracking two different balances (of a different asset even) based on the same share structure poses some issues because the assets don't share the same accounting rules. To correctly account for fees we re-introduce a modified version of **cumulative fee factors** as first described in [LIP-36](https://forum.livepeer.org/t/a-more-gas-efficient-earnings-calculation-approach/1097). In plain english this value allows us to calculate the delegator's share of the increase in fees since the delegator last claimed fees.

The calculations can be simplified further when using share-based accounting, obfuscating the need for a cumulative reward factor (based on stake) for correct calculations.

When a winning ticket comes in the new cumulative fee factor can be calculated as

```
CFF = previousCFF + (fees / activeFeeShares)
```

A delegator's available fees can be calculated as follows

```
fees = delegatorShares * (currentCFF - delegator.lastCFF)
```

An example integration of the library along with a run-down can be found [here](#example-bondingmanager-integration)

## Data Structures

### `Delegation`

Delegation holds the necessary info for delegations to a delegation pool

| Value | type | description |
|-----------|------|-------------|
| `shares`| `uint256`|nominal amount of shares held by the delegation|
|`lastCFF`|`uint256`|cumulative fee factor during last accounting update|

### `Pool`

A delegation pool accrues delegator rewards and fees for an orchestrator and handles accounting

| Value | type | description |
|-----------|------|-------------|
| `totalShares`| `uint256`|total amount of outstanding shares in the delegation pool|
| `activeFeeShares`| `uint256`|portion of total shares eligible for fees, this value is set to totalShares when new fees are added|
|`totalStake`|`uint256`|total amount of tokens held by the EarningsPool|
|`CFF`|`uint256`|the current cumulmative fee factor|
|`delegations`|`mapping (address => Delegation)`|mapping of a delegator's address to a delegation|

## API

### `stake(struct Delegations.Pool _pool, address _delegator, uint256 _amount)` (internal)

Stake an amount of tokens in the pool. Calculates the amount of shares to mint based on the current amount of total stake and outstanding shares. Mints the calculated amount of shares for the delegator and adds the staked amount to the pool's total stake.


#### Parameters

| Parameter | type | description |
|-----------|------|-------------|
| `_pool`|`Delegations.Pool`|  storage pointer to the delegation pool|
| `_delegator`| `address`|address of the delegator that is staking to the pool|
|`_amount`|`uint256`|amount of tokens being staked by the delegator|

### `unstake(struct Delegations.Pool _pool, address _delegator, uint256 _amount)` (internal)

Unstake an amount of tokens from the pool. Calculates the amount of shares to burn based on the current amount of total stake and outstanding shares. Burns the calculated amount of shares from the delegator and subtracts the unstaked amount from the pool's total stake.

#### Parameters

| Parameter | type | description |
|-----------|------|-------------|
| `_pool`|`Delegations.Pool`|  storage pointer to the delegation pool|
| `_delegator`| `address`|ddress of the delegator that is unstaking from the pool|
|`_amount`|`uint256`|amount of tokens being unstaked by the delegator|

### `addRewards(struct Delegations.Pool _pool, uint256 _amount) → uint256 totalStake` (internal)

Add rewards to the delegation pool, increases the total stake in the pool by the specified amount. Returns the new amount of total stake in the pool.

#### Parameters

| Parameter | type | description |
|-----------|------|-------------|
| `_pool`|`Delegations.Pool`|  storage pointer to the delegation pool|
|`_amount`|`uint256`|stake new total stake in the delegation pool|

#### Return values

| Return Value | type | description |
|-----------|------|-------------|
|`totalStake`|`uint256`| new total stake in the delegation pool|

### `mintShares(struct Delegations.Pool _pool, address _delegator, uint256 _amount)` (internal)

Mint a specified amount of new shares for the delegator. Increases the delegator's delegation share amount and total shares.

**NOTE:** Updates totalShares used for stake accounting but not activeFeeShares for fee accounting.

| Parameter | type | description |
|-----------|------|-------------|
| `_pool`|`Delegations.Pool`|  storage pointer to the delegation pool|
| `_delegator`| `address`|address of the delegator to mint shares for|
|`_amount`|`uint256`|amount of shares to mint|

### `burnShares(struct Delegations.Pool _pool, address _delegator, uint256 _amount)` (internal)

Burn existing shares from a delegator. Subtracts the amount of shares to burn from the delegator's delegation and decreases the amount of total shares.

| Parameter | type | description |
|-----------|------|-------------|
| `_pool`|`Delegations.Pool`|  storage pointer to the delegation pool|
| `_delegator`| `address`|address of the delegator to burn shares from|
|`_amount`|`uint256`|amount of shares to burn|

### `addFees(struct Delegations.Pool _pool, uint256 _amount) → uint256 fees` (internal)

Add fees to the delegation pool, increases the fees by the specified amount and returns the new total amount of fees earned by the pool.

#### Parameters

| Parameter | type | description |
|-----------|------|-------------|
| `_pool`|`Delegations.Pool`|  storage pointer to the delegation pool|
|`_amount`|`uint256`|amount of fees to add to the pool|

#### Return Values

| Parameter | type | description |
|-----------|------|-------------|
|`fees`|`uint256`|new total amount of fees in the delegation pool|

### `claimFees(struct Delegations.Pool _pool, address _delegator) → uint256 claimedFees` (internal)

Claim all available fees for a delegator from the delegation pool, returns the claimable amount.

**NOTE:** This only handles state updates to the delegation pool, actual transferring of funds should be handled by the caller

#### Parameters

| Parameter | type | description |
|-----------|------|-------------|
| `_pool`|`Delegations.Pool`|  storage pointer to the delegation pool|
|`_delegator`|`address`|address of the delegator to claim fees for|

#### Return Values

| Parameter | type | description |
|-----------|------|-------------|
|`claimedFees`|`uint256`|amount of fees claimed|

### `stakeOf(struct Delegations.Pool _pool, address _delegator) → uint256 stake` (internal)

Returns the total stake of a delegator.

**NOTE:** Sum of principal and staking rewards

#### Parameters

| Parameter | type | description |
|-----------|------|-------------|
| `_pool`|`Delegations.Pool`|  storage pointer to the delegation pool|
|`_delegator`|`address`|address of the delegator|

#### Return Values

| Parameter | type | description |
|-----------|------|-------------|
|`stake`|`uint256`|stake of the delegator|

### `sharesOf(struct Delegations.Pool _pool, address _delegator) → uint256 shares` (internal)

Returns the nominal amount of shares of a delegation pool owned by a delegator.

#### Parameters

| Parameter | type | description |
|-----------|------|-------------|
| `_pool`|`Delegations.Pool`|  storage pointer to the delegation pool|
|`_delegator`|`address`|address of the delegator|

#### Return Values

| Parameter | type | description |
|-----------|------|-------------|
|`shares`|`uint256`|shares of the delegation pool owned by the delegator|

### `feesOf(struct Delegations.Pool _pool, address _delegator) → uint256 fees` (internal)

Returns the amount of claimable fees from a delegation pool for a delegator. Calculated as the delegator's share of the lifetime earned fees in the pool minus the its delegation's `feeCheckpoint`.

#### Parameters

| Parameter | type | description |
|-----------|------|-------------|
| `_pool`|`Delegations.Pool`|  storage pointer to the delegation pool|
|`_delegator`|`address`|address of the delegator|

#### Return Values

| Parameter | type | description |
|-----------|------|-------------|
|`fees`|`uint256`|fees claimable from the delegation pool for the delegator|

### `stakeAndFeesOf(struct Delegations.Pool _pool, address _delegator) → uint256 stake, uint256 fees` (internal)

Returns the amount of stake as well as claimable fees from a delegation pool for a delegator.

More gas efficient to use when fetching both a delegator's stake and fees.

#### Parameters

| Parameter | type | description |
|-----------|------|-------------|
| `_pool`|`Delegations.Pool`|  storage pointer to the delegation pool|
|`_delegator`|`address`|address of the delegator|

#### Return Values

| Parameter | type | description |
|-----------|------|-------------|
|`stake`|`uint256`|stake of the delegator|
|`fees`|`uint256`|fees claimable from the delegation pool for the delegator|

### `tokensToShares(struct Delegations.Pool _pool, uint256 _tokens) → uint256 shares` (internal)

Convert an amount of tokens to the nominal amount of shares it represents in the pool.

Calculated as `_tokens * (totalShares / totalStake)`.

#### Parameters

| Parameter | type | description |
|-----------|------|-------------|
| `_pool`|`Delegations.Pool`|  storage pointer to the delegation pool|
|`_tokens`|`uint256`|amount of tokens to calculate share amount for|

#### Return Values

| Parameter | type | description |
|-----------|------|-------------|
|`shares`|`uint256`|amount of shares that represent the underlying tokens|

### `sharesToTokens(struct Delegations.Pool _pool, uint256 _shares) → uint256 tokens` (internal)

Convert an amount of shares to the amount of tokens in the delegation pool it represents. 

Calculated as `totalStake * (_shares / totalShares)`.

#### Parameters

| Parameter | type | description |
|-----------|------|-------------|
| `_pool`|`Delegations.Pool`|  storage pointer to the delegation pool|
|`_shares`|`uint256`|amount of tokens to calculate share amount for|

#### Return Values

| Parameter | type | description |
|-----------|------|-------------|
|`tokens`|`uint256`|amount of tokens represented by the shares|

## Example `BondingManager` Integration

### `updateOrchestratorWithRewards(address _orchestrator, uint256 _rewards)` (internal)

Updates orchestrator with assigned rewards


Calculates the orchestrator's reward commission based on its reward share and assigns it to the orchestrator
Calculates the amount of tokens to assign to the delegation pool based on the reward amount and the orchestrator's reward share
Adds the calculated amount to the delegation pool, updating DelegationPool.totalStake
This in turn increases the amount of LPT represented by a nominal share amount held by delegators

### `updateOrchestratorWithFees(address _orchestrator, uint256 _fees)` (internal)

Updates orchestrator with fees from a redeemed winning ticket


Calculates the orchestrator's fee commission based on its fee share and assigns it to the orchestrator
Calculates the amount fees to assign to the delegation pool based on the fee amount and the orchestrator's fee share
Adds the calculated amount to the delegation pool, updating DelegationPool.fees
This in turn increases the amount of total fees in the delegation pool, increases the individual fees calculated from the nominal amount of shares held by a delegator

### `stakeOf(address _of) → uint256 stake` (public)

Calculate the total stake for an address


Calculates the amount of tokens represented by the address' share of the delegation pool
If the address is an orchestrator, add its commission
NOTE: currently doesn't support multi-delegation
Delegators don't need support fetching on-chain stake directly, so for multi-delegation we can do calculations off chain
        and repurpose this to 'orchestratorStake(address _orchestrator)'

### `feesOf(address _of) → uint256 fees` (public)

Calculate the withdrawable fees for an address


Calculates the amount of ETH fees represented by the address' share of the delegation pool and its last fee checkpoint
If the address is an orchestrator, add its commission
NOTE: currently doesn't support multi-delegation
Delegators don't need support fetching on-chain fees directly, so for multi-delegation we can do calculations off chain
        and repurpose this to 'orchestratorFees(address _orchestrator)'

### `claimFees(address payable _for)` (internal)

Withdraw fees for an address


Calculates amount of fees to claim using `feesOf`
Updates Delegation.feeCheckpoint for the address to the current total amount of fees in the delegation pool
If the claimer is an orchestator, reset its commission
Transfer funds
NOTE: currently doesn't support multi-delegation, would have to add an orchestrator address param

### `bond(address _orchestrator, address payable _delegator, uint256 _amount)` (internal)

Bond tokens to an orchestrator, updates the delegation for the address on the orchestrator's delegation pool


claims any outstanding fees to update the fees checkpoint for the _delegator, this ensures other delegator's fees don't get diluted
'purchases' shares of the delegation pool based on the current share price (totalShares/totalStake)

### `unbond(address payable _delegator, uint256 _amount)` (internal)

Unbond tokens from an orchestrator, updates the delegation for the address on the orchestrator's delegation pool


claims any outstanding fees to update the fees checkpoint for the _delegator, this ensures other delegator's fees don't get diluted
'sells' shares of the delegation pool based on the current share price (totalShares/totalStake)


