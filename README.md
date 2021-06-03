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

The library used **share-based accounting** whereby a nominal amount of shares represent an intrinsic amount of stake (including rewards) and protocol fees. Meaning that while the amount of shares a user holds can remain unchanged, the amount of stake and fees it represent can fluctuate as rewards/fees are earned or the delegate's stake is slashed.  

## Data Structures

### `Delegation`

Delegation holds the necessary info for delegations to a delegation pool

| Value | type | description |
|-----------|------|-------------|
| `shares`| `uint256`|nominal amount of shares held by the delegation|
|`feeCheckpoint`|`uint256`|amount of fees in the pool after last claim by the delegator|

### `Pool`

A delegation pool accrues delegator rewards and fees for an orchestrator and handles accounting

| Value | type | description |
|-----------|------|-------------|
| `totalShares`| `uint256`|total amount of outstanding shares in the delegation pool|
|`totalStake`|`uint256`|total amount of tokens held by the EarningsPool|
|`fees`|`uint256`|total amount of available fees (claimed or unclaimed, but not withdrawn)|
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

Unstake an amount of tokens from the pool. Calculates the maount of shares to burn based on the current amount of total stake and outstanding shares. Burns the calculated amount of shares from the delegator and subtracts the unstaked amount from the pool's total stake.

#### Parameters

| Parameter | type | description |
|-----------|------|-------------|
| `_pool`|`Delegations.Pool`|  storage pointer to the delegation pool|
| `_delegator`| `address`|ddress of the delegator that is unstaking from the pool|
|`_amount`|`uint256`|amount of tokens being unstaked by the delegator|

### `addRewards(struct Delegations.Pool _pool, uint256 _amount) → uint256 stake` (internal)

Add rewards to the delegation pool, increases the total stake in the pool by the specified amount. Returns the new amount of total stake in the pool.

#### Parameters

| Parameter | type | description |
|-----------|------|-------------|
| `_pool`|`Delegations.Pool`|  storage pointer to the delegation pool|
|`_amount`|`uint256`|stake new total stake in the delegation pool|

#### Return values

| Return Value | type | description |
|-----------|------|-------------|
|`stake`|`uint256`| new total stake in the delegation pool|

### `mintShares(struct Delegations.Pool _pool, address _delegator, uint256 _amount)` (internal)

Mint a specified amount of new shares for the delegator. Increases the delegator's delegation share amount and total shares.

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
