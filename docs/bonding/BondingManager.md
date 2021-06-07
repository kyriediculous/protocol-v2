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


