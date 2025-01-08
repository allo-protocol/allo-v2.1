# Allocation Extensions

Allocation Extensions are modular tools for setting and managing allocation windows within strategies, allowing developers to define allocation periods with customizable criteria, such as time-based windows and eligibility for allocators.

## Available Extensions

- **AllocationExtension**: Core functionality for configuring allocation periods, including start and end times, with optional metadata support to include additional data during allocation events.
- **AllocatorsAllowlistExtension**: Expands on the core `AllocationExtension` by adding an allowlist system, enabling strategies to restrict allocations to specific, approved allocators.

## Key Features

- **Configurable Allocation Windows**: Define allocation periods with specific start and end times, offering precise control over when allocations occur.
- **Allocator Eligibility Management**: Extensions such as `AllocatorsAllowlistExtension` enforce strict eligibility criteria, ensuring only approved allocators participate.
- **Metadata Support**: Optionally structure additional metadata within allocation periods to provide extra detail or functi
