# TokenGatingExtension.sol

The `TokenGatingExtension` contract implements a mechanism for gating access to strategy functions based on ERC20 token holdings. This extension ensures that only participants who hold a specified amount of tokens can call certain functions, enhancing the security and exclusivity of the strategy's operations.

## Table of Contents
- [Smart Contract Overview](#smart-contract-overview)
  - [Errors](#errors)
  - [Modifiers](#modifiers)
  - [Developer Hooks](#developer-hooks)
  - [Internal Functions](#internal-functions)
- [User Flows](#user-flows)
  - [Token Ownership Verification Flow](#token-ownership-verification-flow)

## Smart Contract Overview

- **License:** AGPL-3.0-only
- **Solidity Version:** The contract supports Solidity versions ^0.8.19 but is developed in Solidity version 0.8.22.
- **Inheritance:** The contract inherits from:
  - `BaseStrategy` - provides foundational strategy functionality, enabling gating based on token holdings.

### Errors

1. **`TokenGatingExtension_InvalidToken()`**: Reverts if the provided token address is zero during checks.
2. **`TokenGatingExtension_InvalidActor()`**: Reverts if the provided actor address is zero during checks.
3. **`TokenGatingExtension_InsufficientBalance()`**: Reverts if the actor does not hold the required amount of tokens.

### Modifiers

1. **`onlyWithToken(address _token, uint256 _amount, address _actor)`**
   - Ensures that the specified actor holds at least the specified amount of the specified tokens.
   - **Parameters**:
     - `_token`: Address of the ERC20 token contract.
     - `_amount`: Minimum amount of tokens required.
     - `_actor`: Address of the actor to check for token ownership.
   - Reverts with `TokenGatingExtension_InvalidToken`, `TokenGatingExtension_InvalidActor`, or `TokenGatingExtension_InsufficientBalance` if conditions are not met.

### Developer Hooks

1. **`_checkOnlyWithToken(address _token, uint256 _amount, address _actor)`**
   - Verifies if a participant holds the required amount of tokens by checking the token contract's balance for the actor.
   - **Override Purpose**: Allows for custom validation logic regarding token ownership.
   - **Returns**: `bool` — `true` if the actor owns the required amount of tokens, otherwise reverts with appropriate error.

### Internal Functions

1. **`_checkOnlyWithToken(address _token, uint256 _amount, address _actor)`**
   - Performs checks for valid token and actor addresses and confirms token ownership using the `IERC20` interface.
   - Reverts if the token address or actor address is invalid or if the actor's balance is insufficient.

---

## User Flows

### Token Ownership Verification Flow

1. **Token Check**: When a gated function is called, the `onlyWithToken` modifier invokes `_checkOnlyWithToken` to verify token ownership.
2. **Address Validation**:
   - The function checks if the token and actor addresses are valid (not zero).
3. **Balance Verification**:
   - The contract checks the balance of the actor for the specified token using `IERC20`.
   - If the actor does not hold the required amount of tokens, the function reverts with `TokenGatingExtension_InsufficientBalance`.
4. **Access Grant**:
   - If all checks pass, the function execution continues, granting access to the caller.
