# Tests summary.

## Unit Tests
Written using [Forge Foundry](https://getfoundry.sh/), [Smock](https://github.com/defi-wonderland/smock-foundry) and [Bulloak](https://www.bulloak.dev/),
they cover every contracts of this repository.

To run them, after installing all dependencies, generate the mocks using `[your package manager] smock` (eg `yarn mock`)
then run the tests using `[your package manager] test:unit` (eg `yarn test`).

## Integration Tests
We cover every user story of the strategies.
To run them, after installing depedencies, define both Optimism and Mainnet RPC URL (eg `export MAINNET_RPC_URL=https://etc`), then use `[your package manager] test:integration` (eg `yarn test:integration`).

## Invariant Tests
We assess how 8 invariants are holding against Medusa and Echidna fuzzer (see the PROPERTIES.md file
for the complete list). To run both campaigns, use the following commands:
- `medusa fuzz .` (this is our default tool, configuration is included in this repo)
- `echidna --contract FuzzTest --test-mode assertion test/invariant/fuzz/FuzzTest.t.sol`
