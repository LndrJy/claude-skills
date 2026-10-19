# Public API Reference

Detailed reference for `uplift-public-api` — the read-only Express API serving dashboard data.

## Tech Stack

| Layer | Technology | Version |
|-------|-----------|---------|
| Runtime | Node.js | 20+ |
| Framework | Express | 4.21.2 |
| Language | TypeScript | 5.7.3 |
| Database | PostgreSQL | 16 |
| DB Client | pg | 8.13.3 |
| Validation | Zod | 4.3.6 |
| Security | Helmet | 8.1.0 |
| Rate Limiting | express-rate-limit | 8.3.1 |
| CORS | cors | 2.8.5 |
| Secrets | @aws-sdk/client-secrets-manager | (optional) |

## Project Structure

```
src/
├── index.ts               # Entry point, bootstrap, graceful shutdown
├── app.ts                 # Express middleware stacking
├── config/
│   ├── env.ts             # Typed environment variables with validation
│   ├── database.ts        # pg Pool singleton, AWS Secrets Manager resolution
│   ├── schema.ts          # DDL for all tables (CREATE TABLE IF NOT EXISTS)
│   ├── seed.ts            # Data seeding orchestrator
│   └── init-db.ts         # Schema + seed orchestrator
├── middleware/
│   ├── async-handler.ts   # Wraps async routes to catch rejections
│   ├── error-handler.ts   # Global error handler (sanitized in prod)
│   ├── request-logger.ts  # Color-coded request logging
│   └── validate.ts        # Zod schema validation factory
├── routes/
│   ├── index.ts           # Route aggregator
│   ├── health.ts          # GET /health
│   └── uplift.ts          # GET /api/uplift/* endpoints
└── data/
    └── seed-data.ts       # UPLIFT values + content seed data (EN/FIL)
```

## API Endpoints

All endpoints are **read-only** (GET only) and **unauthenticated**.

### Aggregate Endpoint
```
GET /api/uplift/
  Query: ?lang=en|fil  &sections=savingLives,fuelSupply  (comma-separated filter)
  Returns: { values: {...}, content: {...}, images: [...] }
```
This is the main endpoint consumed by the dashboard webapp. It merges values, content, and images by section.

### Section Listing
```
GET /api/uplift/sections
  Returns: { sections: [{ key, sort_order, created_at, updated_at }] }
```

### Single Section
```
GET /api/uplift/sections/:key
  Query: ?lang=en|fil
  Returns: { key, values, content }
```

### Values (Language-Agnostic Config)
```
GET /api/uplift/values
  Returns: { [sectionKey]: data }  (merged by section_key)

GET /api/uplift/values/:sectionKey
  Returns: raw JSONB data object
```

### Content (Language-Specific Text)
```
GET /api/uplift/content/:lang
  Returns: { [sectionKey]: data }  (merged by section_key)

GET /api/uplift/content/:lang/:sectionKey
  Returns: raw JSONB content object
```

### Images
```
GET /api/uplift/images
  Returns: { images: [{ id, section_key, image_key, blob_url, alt_text }] }

GET /api/uplift/images/:sectionKey
  Returns: { images: [...] }
```

### Health Check
```
GET /health
  Returns: { status: 'ok'|'degraded', timestamp, db: 'connected'|'error' }
  Status: 200 (ok) or 503 (DB error)
```

## Database Schema

### uplift_sections
```sql
CREATE TABLE uplift_sections (
  id SERIAL PRIMARY KEY,
  key VARCHAR(50) UNIQUE NOT NULL,
  sort_order INT DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);
```

### uplift_values
```sql
CREATE TABLE uplift_values (
  id SERIAL PRIMARY KEY,
  section_key VARCHAR(50) UNIQUE NOT NULL,
  data JSONB NOT NULL DEFAULT '{}',
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  updated_by VARCHAR(100)
);
```

### uplift_content
```sql
CREATE TABLE uplift_content (
  id SERIAL PRIMARY KEY,
  section_key VARCHAR(50) NOT NULL,
  lang VARCHAR(3) NOT NULL,          -- 'en' or 'fil'
  data JSONB NOT NULL DEFAULT '{}',
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  updated_by VARCHAR(100),
  UNIQUE (section_key, lang)
);
```

### uplift_images
```sql
CREATE TABLE uplift_images (
  id SERIAL PRIMARY KEY,
  section_key VARCHAR(50) NOT NULL,
  image_key VARCHAR(100),
  blob_url TEXT NOT NULL,
  alt_text VARCHAR(255),
  uploaded_at TIMESTAMPTZ DEFAULT NOW(),
  uploaded_by VARCHAR(100)
);
```

### cms_users (seeded but unused by public API)
```sql
CREATE TABLE cms_users (
  id SERIAL PRIMARY KEY,
  email VARCHAR(255) UNIQUE NOT NULL,
  password_hash VARCHAR(255) NOT NULL,
  name VARCHAR(100),
  created_at TIMESTAMPTZ DEFAULT NOW()
);
```

## Middleware Stack (Applied in Order)

1. **Helmet** — Security headers (CSP disabled for API-only)
2. **CORS** — Configurable origins, methods: GET/POST/PUT/DELETE/OPTIONS, headers: Content-Type/x-api-key/Authorization
3. **Rate Limiting** — Configurable requests per window (default 100/15min, 0 = disabled)
4. **Body Parser** — express.json with 1MB limit
5. **Request Logger** — Color-coded method/url/status/duration
6. **Favicon Suppression** — GET /favicon.ico returns 204
7. **Routes** — Aggregated handlers
8. **Error Handler** — Global catch-all (sanitized messages in prod)

## Error Response Format

```json
{
  "error": {
    "code": "NOT_FOUND | VALIDATION_ERROR | RATE_LIMITED | SERVER_ERROR",
    "message": "Human-readable message",
    "details": [{ "field": "query.lang", "message": "..." }],
    "stack": "..."
  }
}
```
- 4xx: message returned as-is
- 5xx: generic message in production
- `details` only on validation errors
- `stack` only in development

## Seed Data Structure

The `upliftValues` object in `src/data/seed-data.ts` contains:
- `media.newsThumbnails` — News thumbnail URLs per section
- `media.otherNewsThumbnails` — Additional news images
- `media.banners` — Section banner image URLs
- `media.video` — Video URLs
- `savingLives` — Repatriation stats, fund flow data, news links
- `fuelSupply` — Fuel inventory, price data
- `vulnerableSectors` — Social welfare stats
- `foodPrices` — Agriculture/food price data
- `electricitySupply` — Power grid stats
- `commuters` — Transportation stats

## Environment Variables

```
PORT=3000
NODE_ENV=development|production
DB_HOST=localhost
DB_PORT=5432
DB_USER=uplift
DB_PASSWORD=uplift_dev
DB_NAME=uplift_api
DB_SECRET_ARN=arn:aws:secretsmanager:...  (optional, overrides user/password)
AWS_REGION=us-east-1                       (for Secrets Manager)
ALLOWED_ORIGINS=*                          (comma-separated in prod)
RATE_LIMIT_MAX=100                         (0 = disabled)
RATE_LIMIT_WINDOW_MS=900000                (15 minutes)
```

## Docker & Deployment

- **docker-compose.yml**: PostgreSQL 16 + pgAdmin 4 + API service
- **Dockerfile**: Multi-stage build, non-root user (appuser:1001), health check, dumb-init
- **Graceful Shutdown**: SIGTERM/SIGINT handlers close DB pool and HTTP server
- **Database Init**: Schema DDL + seed data on startup (CREATE IF NOT EXISTS = idempotent)

## Known Gaps

- No authentication on any endpoints (public API by design, but no write protection)
- No POST/PUT/DELETE endpoints implemented
- No test framework configured
- No ORM (raw SQL queries)
- No logging framework (console.log)
- No API documentation generation (OpenAPI/Swagger)
- No database migrations (DDL on startup only)
