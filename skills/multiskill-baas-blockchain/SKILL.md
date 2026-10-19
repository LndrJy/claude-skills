---
name: multiskill-baas-blockchain
description: >
  Bundle skill — loads the full blockchain / Solidity / EVM toolset in one
  shot. Use when working on smart contract code, on-chain reads/writes,
  contract upgrades, gas economics, L2 selection, or planning the
  Polygon → Glassnet (Prismo zkEVM) migration. Covers OpenZeppelin
  Contracts patterns, proxy/upgrade safety, real-world gas pricing,
  verified contract addresses, L2 landscape, and Ethereum token standards.
  Triggers: Solidity, smart contract, OpenZeppelin, OZ, ERC-20, ERC-721,
  ERC-1155, ERC-4337, ERC-7702, ERC-8004, ERC-3009, proxy, upgradeable,
  UUPS, Transparent proxy, Beacon, ProxyAdmin, namespaced storage,
  ERC-7201, Hardhat, Foundry, gas optimization, gas price, gwei, L2,
  Layer 2, Arbitrum, Optimism, Base, zkSync, Scroll, Polygon CDK, Glassnet,
  Prismo, Blockscout, reentrancy, oracle manipulation, vault inflation,
  contract address verification.

  Loads these specialist skills sequentially:
    - skill-oz-develop-secure-contracts
    - skill-oz-upgrade-solidity-contracts
    - skill-oz-setup-solidity-contracts
    - skill-eth-security
    - skill-eth-addresses
    - skill-eth-l2s
    - skill-eth-gas
    - skill-eth-standards
    - skill-nodejs-keccak256
    - skill-evm-token-decimals

  Use this bundle when the task spans contract code + chain economics +
  upgrade safety. For pure backend chain reads (no Solidity), use
  `multiskill-baas-evm` instead. For Solidity-only work without
  Lumen-stack concerns, invoke the OZ skills directly.
---

# BaaS Blockchain Stack Bundle

This bundle activates the **full Solidity + EVM toolset** for working on the smart-contract layer of Lumen and adjacent chain work. Use whenever you're touching `mvp-baas-contracts`, writing/reviewing Solidity, planning a chain migration, or making gas/L2/upgrade decisions.

## What this bundle loads

When this skill triggers, invoke the `Skill` tool for each of the following — in priority order. Loading all 10 gives you the complete picture; load a subset if your task is narrow.

### Contract authoring + upgrade safety (OpenZeppelin)

1. **`skill-oz-develop-secure-contracts`** — OpenZeppelin Contracts patterns: ERC20/721/1155, Ownable, AccessControl, Pausable, ReentrancyGuard, Governor. Lumen's `ERC721Files` extends OZ ERC721 — this skill is the authoritative reference for those base contracts.
2. **`skill-oz-upgrade-solidity-contracts`** — UUPS / Transparent / Beacon proxy patterns, initializers, ERC-7201 namespaced storage, storage layout rules, Hardhat/Foundry upgrades plugins, upgrade validation. Lumen uses `TransparentUpgradeableProxy` + `ProxyAdmin` — this skill prevents storage-collision footguns.
3. **`skill-oz-setup-solidity-contracts`** — Hardhat / Foundry project setup, OZ dependency install, Foundry remappings, Solidity import conventions. Use when bootstrapping a new contract or repo.

### Ethereum production knowledge

4. **`skill-eth-security`** — Solidity security patterns: reentrancy guards, oracle-manipulation defences, token-decimals safety, vault-inflation prevention. Pre-deploy audit checklist. Complements `skill-nodejs-keccak256` + `skill-evm-token-decimals` (BE-side traps).
5. **`skill-eth-addresses`** — Verified on-chain contract addresses across mainnet + L2s (Uniswap, Aave, Lido, USDC, Permit2, Chainlink, …). Prevents address hallucination when integrating external protocols. Useful when migrating to Glassnet and re-anchoring addresses.
6. **`skill-eth-l2s`** — L2 landscape (Arbitrum, Optimism, Base, zkSync, Scroll, Unichain, Celo). How they work, deploy patterns, bridge mechanics, when to use which. Directly applicable to the Glassnet (Prismo zkEVM) migration — Glassnet is the same family of CDK L2s covered here.
7. **`skill-eth-gas`** — Real-world gas pricing (0.05–0.3 gwei on L2s vs mainnet). Gas-station refuel decisions, cost estimation. Replaces stale "mainnet gas is $50" mental models.
8. **`skill-eth-standards`** — ERC-20, ERC-721, ERC-1155, ERC-4337 (account abstraction), ERC-7702, ERC-8004. When to use each, key interfaces. Useful for integrating new standards into BridgePass or future entity types.

### Already in your stack (BE-side EVM safety)

9. **`skill-nodejs-keccak256`** — Node's `sha3-256` ≠ Ethereum's Keccak-256. Prevents silent failures in selectors, signatures, storage slots, address derivation.
10. **`skill-evm-token-decimals`** — ERC-20/721 decimal-mismatch traps across chains. Bridged-token precision drift.

## When to use this bundle vs other bundles

| Task | Use | Why |
|---|---|---|
| Reviewing or writing Solidity contract code | **this bundle** | OZ + eth-security cover authoring |
| Planning a contract upgrade or deploying a new proxy | **this bundle** | `skill-oz-upgrade-solidity-contracts` is the focus |
| Planning the Glassnet migration | **this bundle** + `multiskill-baas-architect` | L2 patterns + ADR + legacy modernization |
| Reading on-chain data from the BE (no Solidity) | `multiskill-baas-evm` | TS-side ethers + Temporal, not Solidity |
| Designing a brand-new token standard or contract from scratch | **this bundle** + `multiskill-baas-architect` | Standards + architecture review |
| Gas station refuel logic | **this bundle** (`skill-eth-gas`) + `multiskill-baas-evm` | Cost economics + on-chain calls |

## Workspace-specific pointers

- **Contracts repo**: `mvp-baas-contracts` (sibling to this BaaS backend). 10 contracts including ERC721Files, Lumen, Organization, 4 ActionPolicy variants, and TransparentUpgradeableProxy + ProxyAdmin.
- **Compiler**: Solidity 0.8.4+ (currently). OpenZeppelin Contracts v4 era (verify before any upgrade — v5 broke some Ownable signatures).
- **Upgrade pattern**: TransparentUpgradeableProxy + ProxyAdmin (not UUPS). `skill-oz-upgrade-solidity-contracts` covers both — read the Transparent section.
- **Chain target**: Polygon Amoy (testnet DEV/STAGING) + Polygon Mainnet (PROD). Migration target: Glassnet (Prismo CDK Erigon zkEVM) — see `GLASSNET_MIGRATION_PREREQ.md` at the repo root.
- **Verification**: Currently Polygonscan via `PolygonscanVerifier.ts` (Etherscan V2 API). Glassnet will require Blockscout — see `skill-eth-l2s` for L2 explorer patterns.
- **Gas token**: MATIC today, likely ETH on Glassnet. Defaults in `GasStation.ts` (70 MATIC / 50 MATIC) need recalibration during migration — `skill-eth-gas` informs the new numbers.

For workspace-wide architecture context, also load `skill-baas-backend`. For the BE-side ethers + Temporal flow, also load `multiskill-baas-evm`.
