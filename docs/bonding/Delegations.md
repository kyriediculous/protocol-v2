## `Delegations`






### `stake(struct Delegations.Pool _pool, address _delegator, uint256 _amount)` (internal)

Stake an amount of tokens in the pool, mints an amount of shares representing the nominal amount of tokens staked in return




### `unstake(struct Delegations.Pool _pool, address _delegator, uint256 _amount)` (internal)

Unstake an amount of tokens from the pool, burns an amount of shares representing the nominal amount of tokens unstaked




### `addRewards(struct Delegations.Pool _pool, uint256 _amount) → uint256 stake` (internal)

Add to total stake in the pool




### `mintShares(struct Delegations.Pool _pool, address _delegator, uint256 _amount)` (internal)

Mint new shares for the pool




### `burnShares(struct Delegations.Pool _pool, address _delegator, uint256 _amount)` (internal)

Burn existing shares from the pool




### `addFees(struct Delegations.Pool _pool, uint256 _amount) → uint256 fees` (internal)

Add to total fees in the pool




### `claimFees(struct Delegations.Pool _pool, address _delegator) → uint256 claimedFees` (internal)

Claim fees from the delegation pool


This only handles state updates to the delegation pool, actual transferring of funds should be handled by the caller


### `stakeOf(struct Delegations.Pool _pool, address _delegator) → uint256 stake` (internal)

Returns the total stake of a delegator


Sum of principal and staking rewards


### `sharesOf(struct Delegations.Pool _pool, address _delegator) → uint256 shares` (internal)

Returns the nominal amount of shares of a delegation pool owned by a delegator




### `feesOf(struct Delegations.Pool _pool, address _delegator) → uint256 fees` (internal)

Returns the amount of claimable fees from a delegation pool for a delegator




### `tokensToShares(struct Delegations.Pool _pool, uint256 _tokens) → uint256 shares` (internal)

Convert an amount of tokens to the nominal amount of shares it represents in the pool




### `sharesToTokens(struct Delegations.Pool _pool, uint256 _shares) → uint256 tokens` (internal)

Convert an amount of shares to the amount of tokens in the delegation pool it represents





