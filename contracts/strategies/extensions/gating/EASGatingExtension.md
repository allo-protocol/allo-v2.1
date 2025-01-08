# EASGatingExtension.sol

The `EASGatingExtension` contract provides an attestation-based gating mechanism for strategies, allowing only entities with specific attestations to interact with gated functions. This contract leverages the Ethereum Attestation Service (EAS) to authenticate participants based on provided schemas and attesters. It serves as a robust extension to enforce conditional access in scenarios that require secure attestation validation.

## Table of Contents
- [Smart Contract Overview](#smart-contract-overview)
  - [Storage Variables](#storage-variables)
  - [Errors](#errors)
  - [Modifiers](#modifiers)
  - [Developer Hooks](#developer-hooks)
  - [Internal Functions](#internal-functions)
- [User Flows](#user-flows)
  - [Attestation Check Flow](#attestation-check-flow)

## Smart Contract Overview

- **License:** AGPL-3.0-only
- **Solidity Version:** The contract supports Solidity versions ^0.8.19 but is developed in Solidity version 0.8.22.
- **Inheritance:** The contract inherits from:
  - `BaseStrategy` - provides foundational strategy functionality, enabling the use of EAS attestations for gating.

### Storage Variables

1. **`eas`** (`address`, Public): The address of the Ethereum Attestation Service (EAS) contract, used to interact with and validate attestations.

### Errors

1. **`EASGatingExtension_InvalidEASAddress()`**: Reverts if the EAS contract address is set to zero during initialization.
2. **`EASGatingExtension_InvalidAttestationSchema()`**: Reverts if the attestation schema does not match the required schema for the function.
3. **`EASGatingExtension_InvalidAttestationAttester()`**: Reverts if the attester does not match the expected attester address for the function.

### Modifiers

1. **`onlyWithAttestation(bytes32 _schema, address _attester, bytes32 _uid)`**
   - Ensures that the sender has a valid attestation with the specified schema and attester.
   - **Parameters**:
     - `_schema`: Unique identifier of the required schema.
     - `_attester`: Expected address of the attester.
     - `_uid`: Unique identifier of the attestation.
   - Reverts with `EASGatingExtension_InvalidAttestationSchema` or `EASGatingExtension_InvalidAttestationAttester` if conditions are not met.

### Developer Hooks

1. **`_checkOnlyWithAttestation(bytes32 _schema, address _attester, bytes32 _uid)`**
   - Verifies if a participant meets the required attestation criteria.
   - **Override Purpose**: Allows custom attestation verification rules.
   - **Returns**: `bool` — `true` if attestation conditions are met, otherwise `false`.

### Internal Functions

1. **`_checkOnlyWithAttestation(bytes32 _schema, address _attester, bytes32 _uid)`**
   - Retrieves attestation details from EAS and verifies if they match the required schema and attester.
   - Reverts if the schema or attester do not align with expected values.

### External/Public Functions

1. **`__EASGatingExtension_init(address _eas)`**
   - Initializes the EAS contract address, ensuring it is a non-zero address.
   - **Parameters**:
     - `_eas`: Address of the EAS contract.
   - Reverts with `EASGatingExtension_InvalidEASAddress` if `_eas` is zero.

---

## User Flows

### Attestation Check Flow

1. **Initialization**: The contract deployer sets the `eas` contract address during initialization using `__EASGatingExtension_init`.
2. **Attestation Verification**:
   - When a gated function is called, the `onlyWithAttestation` modifier checks if the caller has a valid attestation.
   - Attestation details (schema and attester) are validated against the provided parameters.
3. **Access Grant**:
   - If validation passes, the function proceeds. If not, it reverts with either `EASGatingExtension_InvalidAttestationSchema` or `EASGatingExtension_InvalidAttestationAttester`.
