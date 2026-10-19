---
name: skill-uplift-dev
description: >
  Development companion for the UPLIFT Crisis Dashboard Platform — a 4-repo full-stack system comprising
  uplift-dashboard-webapp (React 19 public dashboard), uplift-public-api (Express/PostgreSQL read-only API),
  uplift-cms-webapp (React 19 CMS editor), and uplift-cms-api (Express/PostgreSQL CMS backend with auth,
  media uploads, change requests, and audit logs). Trigger whenever the user mentions UPLIFT, uplift dashboard,
  crisis dashboard, uplift CMS, uplift API, uplift public API, or any related task. Also trigger for:
  section pages (savingLives, fuelSupply, vulnerableSectors, foodPrices, electricitySupply, commuters),
  landing page, uplifting news, CMS edit mode, CMS toolbar, CMS sidebar, editable fields, media upload,
  change requests, audit log, bilingual content (EN/FIL), UpliftDataContext, CmsDataContext, LangContext,
  SectionPageLayout, LandingHeroA, PreviewHeroA, PreviewSectionPage, EditableField, EditableLinks,
  MediaUploadField, CmsLayout, CmsToolbar, ProtectedRoute, @byc-uplift/design-system, deck.gl, mapbox,
  recharts, Sankey fund flow, motion animations, Tailwind v4 design tokens, VITE_PUBLIC_API_URL,
  VITE_CMS_API_URL, uplift_sections table, uplift_values table, uplift_content table, uplift_images table,
  cms_users table, cms_change_requests, cms_audit_log, Azure Blob Storage media, JWT auth with refresh tokens,
  Zod validation, asyncHandler, Helmet, rate limiting, Docker multi-stage builds, Nginx SPA routing,
  or architecture questions about the UPLIFT platform. Even if the user just says "help me with UPLIFT",
  "working on the dashboard", "CMS changes", or "public API" — use this skill.
  Also trigger for new modules and patterns: UPLIFTing News, Balitang UPLIFT, news article, article body blocks,
  paragraph block, bullets block, image block, image carousel, page banner, page settings, page-level CMS,
  contact page, agencies, agency directory, agency logos, agency hotline, agency socials, visibility flags,
  news visibility, landing visibility, scaffold-by-section CMS pattern, MediaUploadField file size limits
  (5MB image / 50MB video), JSON Schema emit, zod-to-json-schema, staging admin script, create-staging-admin,
  three-environment setup (development/staging/production).
---

# UPLIFT Platform Development Skill

A development companion for building, extending, debugging, and operating the UPLIFT Crisis Dashboard Platform — a Philippine government crisis response data visualization and content management system.

## Who this is for

The developer using this skill knows TypeScript and React but may be new to:
- The 4-repo architecture and how data flows between them
- The CMS edit mode pattern (inline editing, change requests, audit trail)
- The bilingual content system (EN/FIL) with static fallbacks
- Deck.gl/Mapbox geographic visualizations
- The section-based content organization (values vs content vs images)
- Azure Blob Storage for media uploads
- JWT auth with token rotation in the CMS

Always explain UPLIFT-specific patterns with concrete examples. When discussing data flow, trace from CMS editor through API to public dashboard. Define section keys and their purpose on first use.

## What is UPLIFT

UPLIFT is a **Philippine government crisis dashboard platform** for visualizing and managing crisis response data. Key facts:

- **4 Repositories**: dashboard-webapp, public-api, cms-webapp, cms-api
- **Public Dashboard**: React 19 + Vite, Tailwind v4, deck.gl/Mapbox maps, Recharts, Motion animations
- **Public API**: Express 4 + PostgreSQL 16 (read-only, no auth required)
- **CMS Webapp**: React 19 + Vite, inline editing UI, change request workflow
- **CMS API**: Express 4 + PostgreSQL 16, JWT auth, Azure Blob Storage, audit logging
- **Design System**: `@byc-uplift/design-system` v1.0.0 (shared across both webapps)
- **Bilingual**: English (en) and Filipino (fil) with localStorage persistence
- **6 Crisis Sections**: savingLives, fuelSupply, vulnerableSectors, foodPrices, electricitySupply, commuters
- **Additional Pages**: landing, media, upliftingNewsPage, contactPage

## Architecture Overview

### System Topology

```
                    Public Users
                        |
                        v
            uplift-dashboard-webapp        (React 19, port 5200)
                   |          |
                   v          v
         uplift-public-api    Mapbox/deck.gl
         (Express, port 3000)
                   |
                   v
              PostgreSQL 16  <--- shared database
                   ^
                   |
         uplift-cms-api            Azure Blob Storage
         (Express, port 3001)      (media uploads)
                   ^
                   |
            uplift-cms-webapp          (React 19, port 5300)
                        ^
                        |
                  CMS Admin Users
```

### Data Model (3-Part Content Structure)

All content is organized into sections with three parallel data stores:

| Store | Table | Purpose | Language-aware? |
|-------|-------|---------|-----------------|
| **Values** | `uplift_values` | Numbers, links, config (shared across languages) | No |
| **Content** | `uplift_content` | Text, titles, descriptions (translated) | Yes (en/fil) |
| **Images** | `uplift_images` | Media references (Azure Blob URLs) | No |

Each section key (e.g., `savingLives`, `fuelSupply`) has one values row, two content rows (en + fil), and N image rows.

### Section Keys

| Key | Dashboard Page | Crisis Domain |
|-----|---------------|---------------|
| `landing` | Landing page hero + topbar | Aggregate overview |
| `savingLives` | Saving Lives section | OFW repatriation, evacuation |
| `fuelSupply` | Fuel Supply section | Energy, fuel inventory |
| `vulnerableSectors` | Vulnerable Sectors section | Social welfare |
| `foodPrices` | Food Prices section | Agriculture, P20 bigas |
| `electricitySupply` | Electricity Supply section | Power grid, rates |
| `commuters` | Commuters section | Transportation, routes |
| `media` | News sidebar | News thumbnails, videos |
| `upliftingNewsPage` | `/news` + `/news/:slug` (CMS-driven) | Article list, full articles, banner, page labels, optional landing-carousel video |
| `contactPage` | `/contact` + landing agency-logo strip | Agency directory (name, logo, hotline, email, address, socials) with `visibility: { contact, landing }` |

### Data Flow: CMS to Public Dashboard

```
CMS Editor (uplift-cms-webapp)
    |
    | PUT /api/cms/values/:sectionKey
    | PUT /api/cms/content/:lang/:sectionKey
    | POST /api/cms/images/upload
    v
CMS API (uplift-cms-api)
    |
    | writes to PostgreSQL (uplift_values, uplift_content, uplift_images)
    | writes to Azure Blob Storage (media files)
    | logs to cms_audit_log
    v
PostgreSQL 16 (shared database)
    ^
    | reads from same tables
    |
Public API (uplift-public-api)
    |
    | GET /api/uplift?lang=en&sections=savingLives,fuelSupply,...
    v
Dashboard (uplift-dashboard-webapp)
    |
    | UpliftDataContext fetches per-route sections
    | merges with static fallback content
    v
Public Users (browser)
```

## Reference Files

This skill has detailed reference files for each repository. **Read the relevant reference before answering repo-specific questions:**

| File | When to read | Covers |
|------|-------------|--------|
| `references/dashboard-webapp.md` | Public dashboard UI, components, animations, maps, charts | React 19 + Vite, routing, UpliftDataContext, LangContext, motion animations, deck.gl/Mapbox, Recharts, Sankey, component patterns, styling |
| `references/public-api.md` | Public API endpoints, database, caching | Express 4, PostgreSQL, read-only endpoints, middleware stack, seed data, Docker, environment variables |
| `references/cms-webapp.md` | CMS editor UI, edit mode, inline editing, media uploads | React 19 + Vite, CmsDataContext, AuthContext, EditableField, EditableLinks, MediaUploadField, change requests, toolbar/sidebar |
| `references/cms-api.md` | CMS backend, auth, media, change requests, audit log | Express 4, PostgreSQL, JWT auth, Azure Blob Storage, Multer uploads, approval workflow, audit trail, Zod validation |

## How to Help

### When the user asks about the overall architecture or "how does X flow"
1. Start with the system topology diagram above
2. Trace data from CMS editor → CMS API → PostgreSQL → Public API → Dashboard
3. Explain the 3-part content model (values/content/images)
4. Note: both APIs share the same PostgreSQL database

### When the user is working on the public dashboard
1. Read `references/dashboard-webapp.md`
2. Key patterns: lazy routing, UpliftDataContext with static fallbacks, motion animations
3. Pages are section-based: LandingPage, SavingLivesPage, FuelSupplyPage, etc.
4. Components: LandingHeroA (hero grid), SectionPageLayout (reusable section wrapper), LandingNews (sidebar)
5. Styling: Tailwind v4 with @byc-uplift/design-system tokens

### When the user is working on the CMS webapp
1. Read `references/cms-webapp.md`
2. Key patterns: edit mode toggle, inline EditableField, deep-set path updates, dirty tracking
3. Edit flow: toggle edit → modify fields → save → API writes → exit edit mode
4. Auth: JWT with auto-refresh on 401, ProtectedRoute wrapper
5. Three parallel state trees: upliftValues, upliftEN, upliftFIL

### When the user is working on either API
1. Read `references/public-api.md` or `references/cms-api.md`
2. Public API: read-only, no auth, section-filtered queries
3. CMS API: full CRUD, JWT auth required, multi-stage approval workflow (`cms_submissions`), audit logging
4. Both use: asyncHandler wrapper, Zod validation, Helmet, CORS, rate limiting
5. Database: raw pg queries (no ORM), JSONB columns for flexible content

### When the user asks about content editing or CMS workflow
1. Read `references/cms-webapp.md` + `references/cms-api.md`
2. Edit mode: global toggle, locks sidebar navigation, tracks active editors
3. EditableField: path-based access (e.g., "savingLives.title"), supports text/textarea/number/url
4. Change requests: submit → review → approve/reject → audit log
5. Exiting edit mode discards unsaved changes (no confirmation dialog)

### When the user asks about bilingual content
1. Language stored in localStorage as `uplift-lang`
2. LangContext provides `lang` and `setLang` across both webapps
3. Content table has (section_key, lang) unique constraint
4. Dashboard: UpliftDataContext fetches with `?lang=en|fil` parameter
5. CMS: separate upliftEN and upliftFIL state trees, editable per-language

### When the user asks about media/images
1. CMS uploads via Multer → Azure Blob Storage
2. Blob path: `{sectionKey}/{timestamp}-{filename}` (images), `{sectionKey}/video/{timestamp}-{filename}` (videos)
3. Metadata stored in `uplift_images` table (blob_url, alt_text, media_type)
4. MediaUploadField component shows upload overlay on hover + media library
5. If Azure not configured, uploads log warning but don't crash

### When the user asks about authentication
1. CMS only — public dashboard has no auth
2. JWT with 15-min access tokens + 7-day refresh tokens
3. Token rotation: old refresh token revoked when new pair issued
4. Password: bcrypt cost 12
5. Default admin: admin@uplift.gov.ph / admin123 (seeded)
6. All CMS routes protected except login, refresh, and health

### When the user asks about deployment
1. All repos have Dockerfiles (multi-stage Node build → Nginx/production)
2. Dashboard: Nginx SPA routing on port 3000 (Docker) / 5200 (dev)
3. Public API: Express on port 3000
4. CMS Webapp: Nginx SPA routing on port 3000 (Docker) / 5300 (dev)
5. CMS API: Express on port 3001
6. Vite env vars baked at build time (VITE_* prefix)

## Repository Quick Reference

### uplift-dashboard-webapp (Public Dashboard)
- **Stack**: React 19, TypeScript 5.9, Vite 8, Tailwind v4, Motion, deck.gl, Mapbox, Recharts
- **Dev Port**: 5200
- **Key Dirs**: `src/pages/`, `src/components/landing/`, `src/context/`, `src/services/`
- **Entry**: `src/App.tsx` (lazy routing + providers)
- **Data**: `UpliftDataContext` fetches from public API with static fallback

### uplift-public-api (Public API)
- **Stack**: Express 4, TypeScript 5.7, PostgreSQL 16, Zod, Helmet
- **Dev Port**: 3000
- **Key Dirs**: `src/routes/`, `src/config/`, `src/middleware/`, `src/data/`
- **Entry**: `src/index.ts` → `src/app.ts`
- **Endpoints**: `GET /api/uplift/*` (read-only, section-filtered)

### uplift-cms-webapp (CMS Editor)
- **Stack**: React 19, TypeScript 5.9, Vite 8, Tailwind v4, Motion
- **Dev Port**: 5300
- **Key Dirs**: `src/components/cms/`, `src/components/preview/`, `src/context/`, `src/services/`
- **Entry**: `src/App.tsx` (routing + auth + CMS providers)
- **Data**: `CmsDataContext` with dirty tracking + `AuthContext` for JWT

### uplift-cms-api (CMS Backend)
- **Stack**: Express 4, TypeScript 5.7, PostgreSQL 16, Zod, JWT, Azure Blob Storage, Multer
- **Dev Port**: 3001
- **Key Dirs**: `src/routes/`, `src/config/`, `src/middleware/`, `src/services/`
- **Entry**: `src/index.ts` → `src/app.ts`
- **Endpoints**: `/api/cms/*` (auth, sections, values, content, images, change-requests, audit-log)

## Common Patterns to Teach

- **3-Part Content Model**: Values (numbers/config, language-agnostic) + Content (text, per-language) + Images (blob URLs). Think of it as: values = the data, content = the words, images = the media.

- **Static Fallback Pattern**: Dashboard has hardcoded EN/FIL content in `src/data/static-content.ts`. If the public API fails or returns null, the dashboard gracefully falls back to static content: `content = { ...fallback, ...apiData }`.

- **Section-Based Architecture**: Everything revolves around section keys. A section key like `savingLives` maps to: a database row in values + content, a dashboard page, a CMS editor page, API query filters, and route paths.

- **Edit Mode Guard**: CMS edit mode is a global toggle. When active: sidebar navigation is locked, active editor count tracked, exiting discards all changes. This prevents data loss from accidental navigation.

- **Deep-Set Path Updates**: CMS uses dot-path notation (e.g., `"savingLives.items[0].label"`) with a `deepSet()` utility for immutable nested updates to the JSONB content structure.

- **JWT Token Rotation**: CMS API issues access (15min) + refresh (7 days) token pairs. On refresh, the old refresh token is revoked (deleted from `cms_refresh_tokens` table). Password change revokes ALL tokens.

- **Route-Driven Fetching**: Dashboard's UpliftDataContext only fetches sections needed for the current route, not the entire dataset. Cached per lang+pathname combination.

- **Change Request Workflow**: CMS edits go through: submit (captures old + new data) → review → approve (writes to main tables in transaction) or reject (with reason). All actions logged to audit table.

## Scaffold-by-Section CMS Pattern (canonical, use this for every new section)

The CMS has migrated from inline-EditableField + raw values/content endpoints to a **per-section dedicated CRUD pattern**. UPLIFTing News and Contact Page are the canonical implementations — every new section follows this template.

### Storage shape
- `uplift_values[sectionKey].data` — lang-agnostic identity, ordering, structural fields, URLs, visibility flags.
- `uplift_content[sectionKey][lang].data` — per-lang text only. Items keyed by id/slug.
- Items support optional per-lang **overrides** for fields normally on values (e.g., a Filipino-language thumbnail can override the default in `content.fil.articles[slug].thumbnailUrl`).

### Backend
- `uplift-cms-api/src/schemas/<section>.ts` — Zod schemas (source of truth). Add to `scripts/emit-schemas.ts` so JSON Schema artifacts regenerate.
- `uplift-cms-api/src/routes/<section>.ts` — auth-required CRUD: `GET /page`, `PUT /page/values`, `PUT /page/content` per lang, `POST /:items`, `PUT /:item-id/values`, `PUT /:item-id/content`, `DELETE /:item-id`, `PUT /:items/reorder`. All transactional across the 3 rows. Mount in `routes/index.ts`.
- `uplift-public-api/src/routes/<section>.ts` — read-only `GET /api/<section>?lang=` (visibility-filtered) and `GET /api/<section>/landing?lang=` (trimmed payload for landing). Mount in `routes/index.ts`.

### Visibility flags
Per-item `visibility: { news?: boolean, landing?: boolean, contact?: boolean, ... }` — defaults true. Server-side filter in public-api. Lets admins hide an item from one location without deleting it.

### CMS UI
- `uplift-cms-webapp/src/pages/Cms<Section>Page.tsx` — two-tab shell (Items / Page Settings).
- `uplift-cms-webapp/src/components/cms/<section>/` — `<X>ListPanel`, `<X>Editor`, `<X>PageSettingsPanel`, plus shared body editors (e.g., `BlockEditor` for news).
- Hand-built (no rjsf or auto-form generators). Boomer-friendly: large inputs, plain English labels, EN/FIL inner tabs.
- Use `MediaUploadField` for all uploads — already enforces 5 MB image / 50 MB video limits with toast feedback.
- Add typed wrappers in `uplift-cms-webapp/src/services/api.ts`. Add the route under `<ProtectedRoute>` in `App.tsx`. Add a sidebar entry in `data/section-config.ts`.

### Dashboard
- `UpliftDataContext` resolves the route to a fetch strategy: news/article/contact each have their own `kind` and dedicated endpoint. Sections-based fetches use the original `/api/uplift?sections=` path.
- Landing trimmed endpoints (`/api/.../landing`) populate ambient state slices like `landingLogos` for components that always render on `/`.

### Trigger checklist when adding a new section
1. Zod schemas in cms-api `src/schemas/<section>.ts` + add to `scripts/emit-schemas.ts`.
2. cms-api routes + mount.
3. public-api routes (list, single, optional landing trimmed) + mount.
4. cms-webapp page + components + api wrappers + route + sidebar entry.
5. dashboard-webapp: extend `UpliftDataContext`, add route resolution, refactor or create the public page, drop any hardcoded data.
6. Seed data: `upliftValues.<section>`, `upliftEN.<section>`, `upliftFIL.<section>` in public-api `data/seed-data.ts`. Add `{ key: '<section>', sort_order: N }` to `config/seed.ts`.
7. Tests: cms-api integration suite (CRUD + slug rename + visibility) + public-api read suite (lang switching + visibility filter + landing trimmed).

## Module Reference

### UPLIFTing News (`upliftingNewsPage`)
- **Routes**: `/news` (list), `/news/:slug` (article). CMS at `/uplifting-news`.
- **Items**: articles with `id`, `slug`, `sortOrder`, `thumbnailUrl`, `externalLink?`, `publishedAt?`, `visibility: {news, landing}` in values; `tagline?`, `title`, `heroImage?`, `body[]`, `source?` plus optional `thumbnailUrl`/`externalLink` per-lang overrides in content.
- **Body blocks** (discriminated union): `paragraph` (string), `bullets` (string[]), `image` (`{url, caption?, alt?}`), `imageCarousel` (array of images).
- **Page-level**: `banner: {en: {url, alt?}, fil: {url, alt?}}` and `videoUrl` (optional, shown after cards on landing carousel) in values; `page: {title?, intro?, readMoreLabel, backLabel}` per lang in content.
- **Endpoints**: cms `/api/cms/uplifting-news/*`, public `/api/uplifting-news?lang=` and `/api/uplifting-news/:slug?lang=` and `/api/uplifting-news/landing?lang=`.

### Contact Page (`contactPage`)
- **Routes**: `/contact` (full page) + agency-logo strip on landing `/`.
- **Items**: agencies with `id`, `abbreviation`, `sortOrder`, `logoUrl?`, `website?`, `socials?: {facebook, twitter, instagram, youtube}`, `visibility: {contact, landing}` in values; `name`, `role?`, `hotline?`, `email?`, `address?`, `hoursLabel?` per lang in content.
- **Page-level**: optional `banner` per lang in values; `page: {title?, intro?, agencyHeading?, hotlineLabel, emailLabel, addressLabel, websiteLabel?, footerNote?}` per lang in content.
- **Endpoints**: cms `/api/cms/contact-page/*`, public `/api/contact-page?lang=` and `/api/contact-page/landing?lang=` (trimmed `{logos}` for landing strip).
- **Single source of truth** for the dashboard's landing-page agency-logo strip — same JSONB row, filtered by `visibility.landing`.

## Auth + Staging Admin

- bcrypt(12) password hashing — never crypto-js for passwords.
- JWT access (15 min) + refresh (7 days) with rotation — old refresh token revoked on each refresh.
- `NODE_ENV` is type-guarded to `'development' | 'staging' | 'production'`. Server refuses to boot on any other value.
- JWT secrets (`JWT_SECRET`, `JWT_REFRESH_SECRET`) are required and rejected if equal to the dev fallback strings outside `NODE_ENV=development`.
- **Staging admin script**: `npm run create-staging-admin` in cms-api. Refuses to run with `NODE_ENV=production`. Requires `STAGING_ADMIN_GUARD=yes-create-staging-admin` env. Upserts `staging-admin@uplift.local` / `StagingOnly!2026`.

## File Upload Limits

- **Images**: 5 MB max. Enforced in `MediaUploadField` (client pre-flight) and multer (server). 413 with clear message on overflow.
- **Videos**: 50 MB max.
- **Thumbnails (video posters)**: 5 MB max.
- `GET /api/cms/images/limits` exposes the caps to the FE.

## JSON Schema Emission

`zod-to-json-schema` powers `cms-api/scripts/emit-schemas.ts`, which writes JSON Schema artifacts to `dist/schemas/`. Run `npm run emit-schemas` after editing any Zod schema. Every new section's schemas should be registered in the emit list. Artifacts are designed to be consumed by FE form generators, OpenAPI tools, or any other downstream consumer — Zod stays the single TypeScript-first source, JSON Schema is the cross-language contract.

## Test Infrastructure (Vitest + Postgres)

Both APIs have Vitest test suites in `tests/`. **Safety guard**: setup throws unless `DB_NAME` ends with `_test`. Test DBs run on dedicated ports via `docker-compose.test.yml` (cms-api: 5433, public-api: 5434). Each test truncates relevant tables in `beforeEach`. Azure Blob is mocked. Run with `docker compose -f docker-compose.test.yml up -d` then `npm test`.
