# Dashboard Webapp Reference

Detailed reference for `uplift-dashboard-webapp` — the public-facing React crisis dashboard.

## Tech Stack

| Layer | Technology | Version |
|-------|-----------|---------|
| Framework | React | 19.2.4 |
| Language | TypeScript | 5.9.3 |
| Build | Vite | 8.0.1 |
| Styling | Tailwind CSS | 4.1.0 |
| Design System | @byc-uplift/design-system | 1.0.0 |
| Routing | React Router | 7.13.2 |
| Animations | Motion | 12.38.0 |
| Maps | deck.gl (core, react, layers, aggregation-layers) | 9.2.11 |
| Maps | Mapbox GL + React Map GL | 3.20.0 / 8.1.0 |
| Charts | Recharts | 3.8.1 |
| Sankey | Nivo Sankey | 0.99.0 |
| Icons | Lucide React, React Icons, Fluent UI Icons | various |
| Sanitization | DOMPurify | 3.3.3 |
| Markdown | Marked | 17.0.5 |

## Project Structure

```
src/
├── App.tsx                    # Main routing + providers (LangProvider, UpliftDataProvider)
├── main.tsx                   # React DOM entry
├── app.css                    # Tailwind imports + design tokens + custom utilities
├── pages/                     # Lazy-loaded route pages
│   ├── LandingPage.tsx
│   ├── SavingLivesPage.tsx
│   ├── FuelSupplyPage.tsx
│   ├── VulnerableSectorsPage.tsx
│   ├── FoodPricesPage.tsx
│   ├── ElectricitySupplyPage.tsx
│   ├── CommutersPage.tsx
│   ├── AboutPage.tsx
│   ├── ContactPage.tsx
│   ├── FeedbackPage.tsx
│   ├── AIPage.tsx
│   ├── ArticleOFWReintegration.tsx
│   └── UpliftingNewsPage.tsx
├── components/
│   ├── landing/               # Landing page sections
│   │   ├── LandingHeroA.tsx         # Hero with 4-card grid
│   │   ├── LandingHeader.tsx        # Top header bar
│   │   ├── LandingTopbar.tsx        # Agency navigation bar
│   │   ├── LandingNews.tsx          # News carousel sidebar
│   │   ├── LandingSavingLives.tsx   # Saving Lives section card
│   │   ├── LandingFuelSupply.tsx    # Fuel Supply section card
│   │   ├── LandingVulnerableSectors.tsx
│   │   ├── LandingFoodPrices.tsx
│   │   ├── LandingElectricitySupply.tsx
│   │   ├── LandingCommuters.tsx
│   │   ├── LandingFeedback.tsx
│   │   ├── SectionPageLayout.tsx    # Reusable section page wrapper
│   │   └── index.ts
│   ├── chat/                  # AI chatbot (Phase 3)
│   │   ├── Chatbot.tsx
│   │   └── ChatbotComingSoon.tsx
│   └── common/                # Shared UI components
│       ├── RouteLoadingBar.tsx
│       ├── UpliftLoading.tsx  # Skeletons + error states
│       ├── ErrorMessage.tsx
│       ├── BottomSheet.tsx
│       ├── Skeleton.tsx
│       └── MobileTable.tsx
├── context/
│   ├── LangContext.tsx         # i18n: 'en' | 'fil' with localStorage
│   └── UpliftDataContext.tsx   # CMS data + fallback static content
├── hooks/
│   ├── useFetch.ts             # Generic fetch hook
│   └── useIsMobile.ts          # Breakpoint detection (768px)
├── services/
│   └── api.ts                  # Dashboard API client with TTL caching
├── types/
│   └── api.ts                  # Full API response types
├── data/
│   └── static-content.ts       # Hardcoded nav & content (EN/FIL fallback)
└── lib/
    └── motion.tsx              # Motion wrapper components & variants
```

## Routing (App.tsx)

All pages are lazy-loaded with `React.lazy()`:

| Route | Page | Sections Fetched |
|-------|------|-----------------|
| `/` | LandingPage | landing, savingLives, fuelSupply, vulnerableSectors, foodPrices, electricitySupply, commuters, media |
| `/saving-lives` | SavingLivesPage | savingLives, media |
| `/fuel-supply` | FuelSupplyPage | fuelSupply, media |
| `/vulnerable-sectors` | VulnerableSectorsPage | vulnerableSectors, media |
| `/food-prices` | FoodPricesPage | foodPrices, media |
| `/electricity-supply` | ElectricitySupplyPage | electricitySupply, media |
| `/commuters` | CommutersPage | commuters, media |
| `/about` | AboutPage | (none) |
| `/contact` | ContactPage | (none) |
| `/feedback` | FeedbackPage | (none) |
| `/ai` | AIPage | (none) |
| `/uplifting-news` | UpliftingNewsPage | upliftingNewsPage, media |
| `/article/ofw-reintegration` | ArticleOFWReintegration | articleOFWReintegration |

## Context Providers

### LangContext
- Type: `'en' | 'fil'`
- Persisted in localStorage as `uplift-lang`
- Provides: `lang`, `setLang`
- Used by all content-displaying components

### UpliftDataContext
- Fetches from: `VITE_PUBLIC_API_URL/api/uplift?lang={lang}&sections={routeSections}`
- State: `{ values, content, loading, error }`
- Features:
  - Route-driven fetching (only fetches sections needed for current route)
  - TTL-based caching per lang+pathname key
  - Static content fallback: `content = { ...staticFallback[lang], ...apiContent }`
  - useReducer for state management
  - retry() method on returned data
- Provides: `useUpliftData()` hook returning `{ values, content, loading, error, retry }`

## Component Patterns

### SectionPageLayout (Reusable Page Wrapper)
Used by all section pages (SavingLives, FuelSupply, etc.):
- Props: banner image, dataKey (section key), newsImages config
- Renders: banner, title, description, KPI cards, "What Government Is Doing" links, "Help for Public" links, news sidebar
- Handles: loading skeleton, error states, responsive layout

### LandingHeroA (Hero Grid)
- 4-card responsive grid (1 col mobile, 2 tablet, 4 desktop)
- Each card links to a section page
- Uses motion stagger animations for entrance
- Cards show section icon + title + brief stat

### LandingNews (Sidebar Carousel)
- News items from CMS media.newsThumbnails
- Carousel with pagination
- Shows thumbnail, headline, link

### Motion Animations
Defined in `src/lib/motion.tsx`:
- `PageWrap` — Page-level fade in
- `Section` — Container with stagger children
- `Item` — Individual stagger child (fadeInUp)
- Variants: `stagger`, `fadeInUp`, `textReveal`, `scaleIn`
- Spring physics for transitions

## API Integration

### Service Layer (src/services/api.ts)
- `apiFetch<T>(path, opts)` — Generic fetch with TTL cache (default 1 min)
- `ApiError` class with status code
- Functions:
  - `getDashboard()` — Aggregate dashboard
  - `getCategories()`, `getKpis()`, `getAlerts()`
  - `getFuelInventory()`, `getSankey()`, `getMapPins()`
  - `getAgencies(category?)`

### API Base URLs
- `VITE_API_BASE_URL` — Dashboard data API (default: http://localhost:3000)
- `VITE_PUBLIC_API_URL` — CMS content API (default: http://localhost:3000)

## Styling

### Tailwind v4 + Design System Tokens
From `app.css` @theme block:
- **Fonts**: Sora (display), Inter (body), Aptos (heading), Cascadia Code (mono)
- **Brand Colors**: #073D85, #0652B0, #1C66C9, #162b6b (blue palette)
- **Status Colors**: success (green), warning (amber), danger (red), info (blue)
- **Shadows**: Fluent 2 spec (shadow-fluent-2 through shadow-fluent-64)
- **Border Radius**: sm (2px), md (4px), lg (8px), xl (12px)

### Custom CSS Classes
- `.geo-card`, `.geo-sidebar-col` — Map layout
- `.chat-bubble-bot` — AI chat bubbles
- `.ask-ai-btn` — AI button with sweep animation
- Markdown styling for chat messages

### Responsive Breakpoints
- Mobile-first: `sm:`, `md:`, `lg:`, `xl:`, `2xl:`
- Mobile detection: `useIsMobile()` hook (768px threshold)

## Key Types (src/types/api.ts)

```typescript
ApiMeta          // metadata with version, timestamp
ApiCategory      // crisis categories with agency references
ApiKpi           // key performance indicators
ApiAlert         // crisis alerts with severity
ApiFuelItem      // fuel inventory item
ApiFuelSummary   // fuel summary data
ApiSankeyNode    // Sankey diagram node
ApiSankeyLink    // Sankey diagram link
ApiMapPin        // geographic marker
ApiDashboardResponse // aggregate root response
```

## Environment Variables

```
VITE_APP_TITLE         = "ENRGY Crisis Platform"
VITE_APP_ENV           = "development" | "production"
VITE_API_BASE_URL      = "http://localhost:3000"
VITE_PUBLIC_API_URL    = "http://localhost:3000"
VITE_MAPBOX_TOKEN      = "pk.eyJ1IjoiYnljZGV2Ii..."
VITE_DOE_API_URL       = (future — energy data)
VITE_DBM_API_URL       = (future — budget data)
VITE_PSA_API_URL       = (future — stats data)
VITE_ERC_API_URL       = (future — energy regulator)
VITE_CHATBOT_API_URL   = (Phase 3 — AI assistant)
VITE_CHATBOT_API_KEY   = (Phase 3 — AI assistant)
```

Non-production shows "Sandbox" warning badge (bottom-right).

## Deployment

- **Docker**: Multi-stage Node build → Nginx Alpine serve (port 3000)
- **Nginx**: SPA routing (all paths → index.html)
- **Vite env vars**: Baked at build time via `VITE_*` prefix
- **Build**: `tsc -b && vite build` → `dist/`
