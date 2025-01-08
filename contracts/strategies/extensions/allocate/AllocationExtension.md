# AllocationExtension.sol

The `AllocationExtension` contract provides core storage variables, access control modifiers, and essential allocation period management. Designed to be inherited by other contracts, `AllocationExtension` provides hooks for developers to implement custom logic by overriding specific internal functions.

## Table of Contents
- [Smart Contract Overview](#smart-contract-overview)
  - [Storage Variables](#storage-variables)
  - [Errors](#errors)
  - [Modifiers](#modifiers)
  - [Developer Hooks](#developer-hooks)
  - [Internal Functions](#internal-functions)
  - [External/Public Functions](#externalpublic-functions)
  - [Actors](#actors)
- [User Flows](#user-flows)
  - [Initialize Allocation Extension](#initialize-allocation-extension)
  - [Set Allocation Timestamps](#set-allocation-timestamps)

## Smart Contract Overview

- **License:** AGPL-3.0-only
- **Solidity Version:** The contract supports Solidity versions ^0.8.19, but is developed in Solidity version 0.8.22.
- **Inheritance:** The contract inherits from other contracts: `BaseStrategy` and `IAllocationExtension`.

### Storage Variables

1. `allocationStartTime` (Public `uint64`): Start time of the allocation period.
2. `allocationEndTime` (Public `uint64`): End time of the allocation period.
3. `isUsingAllocationMetadata` (Public `bool`): Indicates if metadata is used.
4. `allowedTokens` (Public `mapping` of `address` to `bool`): Maps tokens to their authorization status.

### Errors

1. `AllocationExtension_INVALID_ALLOCATION_TIMESTAMPS()`: Start time exceeds end time.
2. `AllocationExtension_ALLOCATION_HAS_ALREADY_STARTED()`: Action attempted after allocation start.
3. `AllocationExtension_ALLOCATION_NOT_ACTIVE()`: Action attempted outside the allocation period.
4. `AllocationExtension_ALLOCATION_HAS_NOT_ENDED()`: Action attempted before allocation end.
5. `AllocationExtension_ALLOCATION_HAS_ENDED()`: Action attempted after allocation ended.

### Modifiers

1. `onlyAfterAllocation`: Requires allocation to have ended.
2. `onlyActiveAllocation`: Requires current time within allocation period.
3. `onlyBeforeAllocation`: Requires current time before allocation start.

### Developer Hooks

The following internal functions are meant to be overridden by developers to implement extra custom logic within their strategy contracts:

1. **`_isValidAllocator(address _allocator) -> bool`**
   - Checks if an address is a valid allocator.
   - **Override Purpose**: Implement custom logic to validate allocator permissions or eligibility, such as role-based checks.
   - *Returns*: `bool` — `true` if `_allocator` is valid; otherwise `false`.

2. **`_isAllowedToken(address _token) -> bool`**
   - Verifies if a token is authorized for allocation.
   - **Override Purpose**: Add custom validation, such as conditions based on token metadata.
   - *Returns*: `bool` — `true` if `_token` is allowed; otherwise `false`.

3. **`_updateAllocationTimestamps(uint64 _allocationStartTime, uint64 _allocationEndTime)`**
   - Sets allocation start and end times.
   - **Override Purpose**: Add controls around timestamp updates, such as adjusting based on external time-dependent logic or integration with oracle-based scheduling.
   - *Reverts*: `AllocationExtension_INVALID_ALLOCATION_TIMESTAMPS` if start time exceeds end time.

### Internal Functions

1. **`_checkBeforeAllocation()`**: Ensures allocation has not yet started.
2. **`_checkOnlyActiveAllocation()`**: Ensures function is called within allocation period.
3. **`_checkOnlyAfterAllocation()`**: Ensures function is called after allocation period has ended.

### External/Public Functions

1. **`updateAllocationTimestamps(uint64 _allocationStartTime, uint64 _allocationEndTime)`**: Allows the pool manager to set the allocation period.
   - *Reverts*: Requires `onlyPoolManager`.

### Actors

- **Pool Manager**: Updates allocation parameters.
- **Allocator**: Must meet `_isValidAllocator` criteria to perform allocation actions.

## User Flows

### Initialize Allocation Extension

1. Pool manager calls `__AllocationExtension_init` from the parent strategy's `initialize` function.
2. Sets `_allowedTokens`, `_allocationStartTime`, `_allocationEndTime`, and `_isUsingAllocationMetadata`.

### Set Allocation Timestamps

1. Pool manager calls `updateAllocationTimestamps` with new start and end times.
2. `allocationStartTime` and `allocationEndTime` are updated accordingly.
