# Express vs Azure Functions (mvp-baas-backend)

The SDK runs in two modes from one source tree. Knowing which runtime you're touching matters because they diverge in a few subtle places.

## Side-by-side

| Aspect | Azure Functions | Express |
|---|---|---|
| Entry | `af.js` → `new AzureFunctionInstance()` | `scripts/express-entry.js` → `new ExpressInstance().start()` |
| Identity | Function App per `(entity, module)` — set at deploy | `process.env.LUMEN_API_INSTANCE_ENTITY/MODULE` per local run |
| Local port | 7071 default (overridden by `--port` in runner) | Mapped per (entity, module) in `scripts/port-map.js` |
| Request shape | `HttpRequest` from `@azure/functions` | Express `Request` |
| Normalisation | `RequestNormalizer` abstracts the two so handlers see one shape | Same |
| Auth middleware | `*RequestHandler.wrap(handler, schema)` (function-style) | `parseExplorerListQuery()` etc. (Express middleware) |
| Health check | Built-in via `func start` | Manual: `/health` route |
| Cold starts | Real concern in PROD | None |
| Compiled output | Both consume `dist/` |

## RequestNormalizer

Both runtimes ultimately call into the same entity classes. `RequestNormalizer` (or equivalent abstraction inside `IPreMiddlewareAF` / `IPreMiddleware`) converts the runtime-specific request shape into a `ILumenRequestContext` the handlers consume:

```ts
{
  request: <Zod-validated body>,
  organization?: IOrganizationItem,
  admin?: IAdminItem,
  apiKey?: IAPIKeyItem,
  developer?: IDeveloperItem,
}
```

## When the runtimes diverge

- **Long polling / SSE** — Express supports them natively; Azure Functions HTTP triggers have a 230-second hard timeout. Use Temporal + polling endpoint instead.
- **Background work** — Azure Functions have timer/queue triggers. Express dev path uses `setTimeout`-style schedulers (rare; usually punted to Temporal).
- **Direct WebSocket** — Functions don't support raw WS; Express does. Currently no WS in this codebase.

## Local-dev gotcha

Express requires the compiled `dist/` to exist. The `preexpress` npm hook runs `npm run build:dev` before `express-runner.js` to prevent the "Cannot find module './dist'" error.

Func likewise requires `dist/`. Same `prefunc` hook.

The Express entry imports `../dist` first (side-effect) before `../dist/api/express` — this orders module initialisation correctly and avoids the `Class extends value undefined` circular-dep error.

## See also

- `references/local-dev-runners.md` — runner CLI + port map
- `references/entity-module-pattern.md` — class hierarchy
