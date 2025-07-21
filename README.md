# 💎 Diamond Template

A modular, upgradeable smart contract framework built using the [EIP-2535 Diamond Standard](https://eips.ethereum.org/EIPS/eip-2535). This template provides a clean foundation for building composable and gas-efficient smart contracts with facet-based architecture.

---

## 📦 Features

- ⚙️ **Facets**: Modular smart contract logic components
- 🔁 **Upgradeable**: Add, replace, or remove functions at runtime
- 🧪 **Foundry test suite**: Includes deployment and mutation tests
- 🔍 **Loupe Functions**: Introspect facet addresses and selectors
- 👑 **Role-based Access Control** via `OwnableRolesFacet`
- 📚 **ERC165 Interface Support**
- 🚀 **Automated Deploy Script**

---

## 🛠️ Project Structure

```sh
.
├── src/
│   ├── Diamond.sol                 # Diamond core contract
│   ├── facets/                     # All facets (logic modules)
│   ├── initializer/                # Initializer for setting up ERC165 and others
│   ├── interfaces/                 # Diamond-compliant interfaces (e.g. IDiamondCut)
│   ├── libraries/                  # DiamondStorage, LibDiamond, etc.
│   └── scripts/DeployDiamond.s.sol # Foundry deployment script
│
├── test/
│   ├── DiamondTest.t.sol          # Tests for core diamond behavior
│   └── helpers/                   # Reusable test helpers and states
│
└── foundry.toml                   # Foundry config
```

## 🚀 Getting Started

1. Forge install this repo

```sh
forge install DADADAVE80/diamond-template
```

2. Import the Diamond contract and facets into your project
```solidity
import {Diamond} from "@diamond/Diamond.sol";
import {DiamondCutFacet} from "@diamond/facets/DiamondCutFacet.sol";
import {DiamondLoupeFacet} from "@diamond/facets/DiamondLoupeFacet.sol";
import {OwnableRolesFacet} from "@diamond/facets/OwnableRolesFacet.sol";
```

3. Run Tests

```sh
forge test --ffi -vvv
```

4. Deploy Locally

```sh
forge script script/DeployDiamond.s.sol --fork-url <RPC_URL> --broadcast
```

## 🧩 Facets Included

| Facet             | Purpose                              |
|-------------------|------------------------------------|
| DiamondCutFacet    | Adds/replaces/removes functions     |
| DiamondLoupeFacet  | View functions for facets/selectors |
| OwnableRolesFacet  | Ownership & role-based access       |

---

## 📘 References

- [EIP-2535 Diamond Standard](https://eips.ethereum.org/EIPS/eip-2535)
- [Nick Mudge’s Awesome Diamonds](https://github.com/mudgen/awesome-diamonds)
- [David Dada’s ERC2535 Diamond Example](https://github.com/DADADAVE80/erc2535-diamond-example)

---

## 🧠 License

MIT © 2025  
Built with ♥ by David Dada

---