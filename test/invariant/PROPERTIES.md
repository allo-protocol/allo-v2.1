# Properties & invariants

## General invariants

| id  | property                                                                                                         |
| --- | :--------------------------------------------------------------------------------------------------------------- |
| 1  | manager should be able to allocate for recipient (based on strategy)                                              |
| 2  | manager should be able to distribute correct (based on strategy) allocation for recipient                         |
| 3  | only funds outside the poolAmount can be withdrawn from a pool, by the manager                                    |
| 4  | profile owner can always create a pool                                                                            |
| 5  | anyone can increase fund in a pool, if strategy (hook) logic allows so and if more than base fee                  |
| 6  | every deposit/pool creation must take the correct fee on the amount deposited, forwarded to the treasury          |
| ACC-1 | There is no token which has left the protocol without being accounted for    |
| ACC-2 | Each pool is solvable                     |

The last 2 invariants are general procotol accounting, one based on the actual overal "cash-flow" and one based on the individual pool accounting.

Protocol balance sheet:
| asset                              | liabilities                          |
| ---------------------------------- | ------------------------------------ |
|         tokens in strategies       | withdrawable tokens (unallocated)    |
| (unaccounted tokens in strategies) | tokens to distribute                 |

Note: Allocation doesn't imply token movement. Instead, it set the *future* balance sheet movements,
which will effectively occur when distributing or withdrawing tokens (accounting wise, it's a requalification of liabilities).

## Other important invariant, covered by the unit tests

- pool manager can always withdraw within strategy limits/logic
- allo owner can always recover funds from allo contract ( (non-)native token )
- profile owner is the only one who can always add/remove/modify profile members (name ⇒ new anchor())
- profile owner is the only one who can always initiate a change of profile owner (2 steps)
- profile member can always create a pool
- only profile owner or member can create a pool
- initial admin is always the creator of the pool
- pool admin can always change admin (but not to address(0))
- pool admin can always add/remove pool managers
- pool manager can always change metadata
- allo owner can always change base fee (flat) and percent flee (./. funding amt) to any arbitrary value (max 100%)
- allo owner can always change the treasury address/trustred forwarded/etc
- After a pool creation, getting a pool should always return valid data for profileId and strategy address.
- Allo must be initialised before creating/managing pools
- `percentFee` should never be more than 1e18
- `_poolIndex` should only increase by 1 with each new pool created
- `recoverFunds` should always transfer all the contract’s specified tokens to the recipient
- Funding a pool should always increase the strategy’s `poolAmount`
- Funding a pool should deduct the `percentFee` and transfer the
- Pool must be created before being able to get funds (strategy address is valid)
- Creating a pool should deduct the `baseFee`
- Only a profile of the registry can create a pool
- Two pools can never have the same pool id
- A strategy should never be initialised more than once
- Creating a pool by cloning an existing strategy should deploy the strategy with a clean state
- Creating a pool with an amount higher than 0 should fund the strategy contract with the amount minus the fees
- Creating a pool should always make the sender pool admin
- Two profiles should never have the same anchor
- After creating a profile the owner and anchor must be valid
- Updating the profile’s name should deploy a new anchor
- To change a profile’s owner, the new owner must accept ownership first
