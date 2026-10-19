# Local-Dev Runners (mvp-baas-backend)

## Quick start

```bash
npm run func organization files            # Azure Functions on :7074
npm run express organization files         # Express on :7074
```

Both auto-build (`prefunc` / `preexpress` hooks run `npm run build:dev`) and load `.env` automatically.

## Files

| Path | Role |
|---|---|
| `.env` | **Single source of truth** for DEV secrets (gitignored) |
| `.env.example` | Committed template, mirror of `.env` keys with blank values |
| `host.json` | Azure Functions host config (shared by all modules) |
| `af.js` | Functions entry — `new AzureFunctionInstance()` |
| `scripts/api-runner.js` | `npm run func` — loads `.env`, injects identity, spawns `func start` |
| `scripts/express-runner.js` | `npm run express` — same flow, spawns express-entry |
| `scripts/express-entry.js` | Boots `ExpressInstance().start()` from `dist/api/express` |
| `scripts/port-map.js` | Single source of truth for per-(entity, module) ports |

## Port map (per `scripts/port-map.js`)

| Port | Entity / Module |
|---|---|
| 7071 | ORGANIZATION / ADMIN |
| 7072 | ORGANIZATION / REPORTS |
| 7073 | ORGANIZATION / WALLETS |
| 7074 | ORGANIZATION / FILES |
| 7075 | ORGANIZATION / APIKEYS |
| 7076 | ORGANIZATION / WEBHOOKS |
| 7077 | ORGANIZATION / PAYMENTS |
| 7078 | ORGANIZATION / PLANS |
| 7079 | ORGANIZATION / POLICIES |
| 7080 | ORGANIZATION / GAS_STATION |
| 7081 | BYC_ADMIN / ORGANIZATIONS |
| 7082 | BYC_ADMIN / GAS_STATION |
| 7083 | DEVELOPER / FILES |
| 7084 | DEVELOPER / WALLETS |
| 7085 | DEVELOPER / POLICIES |
| 7086 | DEVELOPER / GAS_STATION |
| 7087 | BRIDGEPASS / USER |
| 7088 | EXPLORER / FILES |

Override at runtime: `PORT=4000 npm run express organization admin`.

## What used to be there (and isn't anymore)

The consolidation removed:
- `local.settings.json` at root — replaced by `.env`
- `api/` tree (17 per-module `local.settings*.json` files + envelope folders)
- Per-module `.env` files under `api/express/{entity}/{module}/`

Identity is now injected by the runner per command, not stored in any folder.

## Full doc

See `c:\Users\irent\OneDrive\Documents\GitHub\mvp-baas-backend\LOCAL_DEV.md` in the repo for the complete how-to (including the troubleshooting table and "bypassing auto-build" notes).
