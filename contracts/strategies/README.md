# BaseStrategy.sol

The `BaseStrategy` contract serves as a foundational building block within the Allo ecosystem, forming the basis for more specialized allocation strategies. By integrating essential functions and variables, this abstract contract establishes a standardized approach for implementing distribution strategies.

## Table of Contents
- [BaseStrategy.sol](#basestrategysol)
  - [Table of Contents](#table-of-contents)
  - [Smart Contract Overview](#smart-contract-overview)
    - [Storage Variables](#storage-variables)
    - [Constructor](#constructor)
    - [Modifiers](#modifiers)
    - [Views and Queries](#views-and-queries)
    - [Functions](#functions)
    - [Internal Functions](#internal-functions)
    - [Hooks](#hooks)

## Smart Contract Overview

* **License:** The `BaseStrategy` contract adheres to the AGPL-3.0-only License, promoting open-source usage with specific terms.
* **Solidity Version:** Supports Solidity versions ^0.8.19, but developed using Solidity version 0.8.22, leveraging the latest Ethereum smart contract advancements.
* **External Libraries:** Imports `Transfer` library from the Allo core for optimized token transfers.
* **Interfaces:** Implements the `IBaseStrategy` interface, facilitating interaction with external components.

### Storage Variables

1. `_ALLO`: An immutable reference to the `IAllo` contract, enabling communication with the Allo ecosystem.
2. `_STRATEGY_ID`: A hash identifying the strategy instance.
3. `_poolId`: Identifies the pool to which this strategy is associated.
4. `_poolAmount`: The current amount of tokens in the pool.

### Constructor

The constructor initializes the strategy by accepting the address of the `IAllo` contract and a name.

### Modifiers

* `onlyAllo`: Validates that the caller is the Allo contract.
* `onlyPoolManager`: Ensures that the caller is a pool manager.

### Views and Queries

1. `getAllo`: Retrieves the `IAllo` contract reference.
2. `getStrategyId`: Retrieves the strategy's ID.
3. `getPoolId`: Retrieves the pool's ID.
4. `getPoolAmount`: Retrieves the current pool amount.

### Functions

1. `increasePoolAmount`: Allows the Allo contract to increase the pool's amount.
2. `withdraw`: Allows the Pool Manager to withdraw tokens from the pool that are not targetted for distribution.
3. `register`: Registers multiple recipients' applications and updates their status.
4. `allocate`: Allocates tokens to recipients based on provided data.
5. `distribute`: Distributes tokens to recipients based on provided data.

### Internal Functions

1. `_checkOnlyAllo`: Checks if the caller is the Allo address.
2. `_checkOnlyPoolManager`: Checks if the address is a pool manager.
4. `_register`: Registers recipients' applications and updates their status.
5. `_allocate`: Allocates tokens to recipients based on provided data.
6. `_distribute`: Distributes tokens to recipients based on provided data.

In essence, the `BaseStrategy` contract establishes a standardized blueprint for various allocation strategies within the Allo ecosystem. It integrates critical functions, modifiers, and data structures, promoting consistency and coherence across different strategies.

Every strategy implemented would be expected to override the internal functions in the base contract. It's important to note that a strategy is expected to implement its own external function when it requires a feature that cannot be met by the internal functions. This design approach allows for flexibility and customization while still adhering to the foundational structure provided by the BaseStrategy contract.

By following this pattern, developers can efficiently create specialized allocation strategies that leverage the standardized building blocks provided by the BaseStrategy contract while tailoring specific functionality as needed for their use cases. This modular approach fosters a robust ecosystem of allocation strategies within the Allo framework, enabling innovative and efficient resource distribution solutions.

### Hooks

In the context of `BaseStrategy.sol`, the concept of hooks is utilized to offer strategies the ability to integrate their custom logic seamlessly into the operations of another strategy. Hooks consist of predefined points during the execution of various functions where additional code can be inserted to modify or enhance the behavior.

Here's a breakdown of how the hooks work:

1. `_beforeIncreasePoolAmount`: This hook is triggered before the pool amount is increased. It allows a strategy to perform specific actions or checks before contributing to the pool.
    
2. `_afterIncreasePoolAmount`: Following the increase in the pool amount, this hook is executed. It enables a strategy to carry out any necessary actions that should occur after the pool amount has been augmented.

3. `_beforeWithdraw`: Before a pool manager withdraws funds from the pool, this hook is executed. A strategy can make use of this to add their custom logic before executing the withdraw.

4. `_afterWithdraw`: After the funds have been withdrawn, this hook is executed. A strategy can override this to add their custom logic.
    
5. `_beforeRegisterRecipient`: Before a recipient is registered, this hook is called. It provides an opportunity for a strategy to implement its own logic before adding a recipient.
    
6. `_afterRegisterRecipient`: Similar to the previous hook, this is executed after a recipient has been registered. A strategy can utilize this to perform tasks after recipient registration.
    
7. `_beforeAllocate`: Prior to allocating funds to a recipient, this hook is triggered. A strategy can define its own pre-allocation actions here.
    
8. `_afterAllocate`: Once the allocation to a recipient is completed, this hook is called. It allows a strategy to execute actions post-allocation.
    
9. `_beforeDistribute`: This hook occurs before the distribution of funds (or tokens) to recipients. Strategies can customize their behavior before the distribution takes place.
    
10. `_afterDistribute`: Following the distribution of funds to recipients, this hook is executed. Strategies can perform tasks after the distribution process concludes.
    

The significance of these hooks is that they facilitate the extension and customization of a base strategy's operations without the need to modify the core logic. Strategies can implement their unique functionalities at these specific points, ensuring seamless integration into the existing strategy's workflow.

In essence, `BaseStrategy.sol` provides a structured way for strategies to inject their own logic before and after key steps of another strategy's execution, promoting modularity and allowing for diversified functionalities in a modular and cohesive manner.