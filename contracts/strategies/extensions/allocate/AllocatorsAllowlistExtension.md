# AllocatorsAllowlistExtension.sol

The `AllocatorsAllowlistExtension` contract provides an extendable system for managing a list of allowed allocators, enabling additional security and control over allocation eligibility within a strategy. The contract inherits core allocation management functionalities and introduces methods for adding or removing allocators by the pool manager.

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
  - [Add Allocator](#add-allocator)
  - [Remove Allocator](#remove-allocator)

## Smart Contract Overview

- **License:** AGPL-3.0-only
- **Solidity Version:** The contract supports Solidity versions ^0.8.19 but is developed in Solidity version 0.8.22.
- **Inheritance:** The contract inherits from:
  - `AllocationExtension` - provides core allocation period controls.
  - `IAllocatorsAllowlistExtension` - interface defining allocator allowlist functionalities.

### Storage Variables

1. `allowedAllocators` (Public `mapping` of `address` to `bool`): Maps allocator addresses to their allowlist status.

### Errors

No specific errors are defined within this contract; however, it inherits errors from `AllocationExtension`.

### Modifiers

The contract does not introduce new modifiers but relies on inherited modifiers from `AllocationExtension`.

### Developer Hooks

1. **`_isValidAllocator(address _allocator) -> bool`**
   - Checks if an allocator is valid by verifying against the `allowedAllocators` mapping.
   - **Override Purpose**: Enables custom allocation rules by modifying or extending the criteria for valid allocators.
   - *Returns*: `bool` — `true` if `_allocator` is allowed, otherwise `false`.

### Internal Functions

1. **`_addAllocator(address _allocator)`**
   - Marks an address as a valid allocator.
   - Can be overridden for additional constraints or custom validation logic.

2. **`_removeAllocator(address _allocator)`**
   - Removes an address from the valid allocator list.
   - Overridable to include specific conditions or custom actions during deactivation.

### External/Public Functions

1. **`addAllocators(address[] memory _allocators)`**
   - Allows the pool manager to add multiple allocators to the allowlist.
   - *Emits*: `AllocatorsAdded` event.

2. **`removeAllocators(address[] memory _allocators)`**
   - Allows the pool manager to remove multiple allocators from the allowlist.
   - *Emits*: `AllocatorsRemoved` event.

### Actors

- **Pool Manager**: Authorized to manage the list of allowed allocators.
- **Allocator**: Must be included in `allowedAllocators` to interact with allocation functionalities.

## User Flows

### Add Allocator

1. Pool manager calls `addAllocators` with an array of allocator addresses.
2. Each address is added to the `allowedAllocators` mapping.
3. The function emits an `AllocatorsAdded` event indicating the allocator addresses and sender.

### Remove Allocator

1. Pool manager calls `removeAllocators` with an array of allocator addresses.
2. Each address is removed from the `allowedAllocators` mapping.
3. The function emits an `AllocatorsRemoved` event indicating the allocator addresses and sender.
