# Allo Protocol Contracts V2.1

## Getting Started

```bash
git clone https://github.com/allo-protocol/allo-v2.1
```

### Install bun

```bash
npm install -g bun
```

### Install Dependencies

```bash
# Install dependencies
bun install
```

> Make sure you have foundry installed globally. [Get it here](https://book.getfoundry.sh/getting-started/installation).


### Build

```bash
bun run build
```

### Test

To run the tests copy `.env.sample` to `.env` and fill in the `MAINNET_RPC_URL` and `OPTIMISM_RPC_URL`.

Some of the tests are using generated mock contracts using [smock-foundry](https://github.com/defi-wonderland/smock-foundry).

```bash
bun run smock
bun run test 
```

### Format

```bash
bun run fmt
```
