# NFTGatingExtension.sol

The `NFTGatingExtension` contract implements a mechanism for gating access to strategy functions based on NFT ownership. This extension ensures that only participants who hold specific NFTs can call certain functions, enhancing the security and exclusivity of the strategy's operations.

## Table of Contents
- [Smart Contract Overview](#smart-contract-overview)
  - [Errors](#errors)
  - [Modifiers](#modifiers)
  - [Developer Hooks](#developer-hooks)
  - [Internal Functions](#internal-functions)
- [User Flows](#user-flows)
  - [NFT Ownership Verification Flow](#nft-ownership-verification-flow)

## Smart Contract Overview

- **License:** AGPL-3.0-only
- **Solidity Version:** The contract supports Solidity versions ^0.8.19 but is developed in Solidity version 0.8.22.
- **Inheritance:** The contract inherits from:
  - `BaseStrategy` - provides foundational strategy functionality, enabling gating based on NFT ownership.

### Errors

1. **`NFTGatingExtension_InvalidToken()`**: Reverts if the provided NFT address is zero during checks.
2. **`NFTGatingExtension_InvalidActor()`**: Reverts if the provided actor address is zero during checks.
3. **`NFTGatingExtension_InsufficientBalance()`**: Reverts if the actor does not own the required NFT.

### Modifiers

1. **`onlyWithNFT(address _nft, address _actor)`**
   - Ensures that the specified actor holds at least one of the specified NFTs.
   - **Parameters**:
     - `_nft`: Address of the NFT contract.
     - `_actor`: Address of the actor to check for NFT ownership.
   - Reverts with `NFTGatingExtension_InvalidToken`, `NFTGatingExtension_InvalidActor`, or `NFTGatingExtension_InsufficientBalance` if conditions are not met.

### Developer Hooks

1. **`_checkOnlyWithNFT(address _nft, address _actor)`**
   - Verifies if a participant holds the required NFT by checking the NFT contract's balance for the actor.
   - **Override Purpose**: Allows for custom validation logic regarding NFT ownership.
   - **Returns**: `bool` — `true` if the actor owns the NFT, otherwise reverts with appropriate error.

### Internal Functions

1. **`_checkOnlyWithNFT(address _nft, address _actor)`**
   - Performs checks for valid NFT and actor addresses and confirms NFT ownership using the `IERC721` interface.
   - Reverts if the NFT address or actor address is invalid or if the actor's balance is insufficient.

---

## User Flows

### NFT Ownership Verification Flow

1. **NFT Check**: When a gated function is called, the `onlyWithNFT` modifier invokes `_checkOnlyWithNFT` to verify ownership.
2. **Address Validation**:
   - The function checks if the NFT and actor addresses are valid (not zero).
3. **Balance Verification**:
   - The contract checks the balance of the actor for the specified NFT using `IERC721`.
   - If the actor does not hold the NFT, the function reverts with `NFTGatingExtension_InsufficientBalance`.
4. **Access Grant**:
   - If all checks pass, the function execution continues, granting access to the caller.
