# CMS Webapp Reference

Detailed reference for `uplift-cms-webapp` — the content management editor for UPLIFT.

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
| Icons | Lucide React, React Icons, Fluent UI Icons | various |
| Sanitization | DOMPurify | 3.3.3 |
| Markdown | Marked | 17.0.5 |

## Project Structure

```
src/
├── App.tsx                        # Route configuration
├── main.tsx                       # Entry point
├── app.css                        # Tailwind + design tokens
├── components/
│   ├── cms/                       # CMS editing UI
│   │   ├── CmsLayout.tsx          # Main layout wrapper
│   │   ├── CmsSidebar.tsx         # Navigation + user actions
│   │   ├── CmsToolbar.tsx         # Edit/preview mode switcher
│   │   ├── EditableField.tsx      # Inline text/number/url editor
│   │   ├── EditableLinks.tsx      # Array of link management
│   │   └── MediaUploadField.tsx   # Image/video upload + library
│   ├── common/
│   │   └── ProtectedRoute.tsx     # Authentication guard
│   └── preview/                   # Content preview components
│       ├── PreviewHeroA.tsx       # Dashboard hero preview
│       ├── PreviewSectionPage.tsx # Section page preview
│       ├── PreviewHeader.tsx      # Header preview
│       └── PreviewTopbar.tsx      # Topbar preview
├── context/
│   ├── AuthContext.tsx             # JWT auth state + auto-refresh
│   ├── CmsDataContext.tsx         # Values/EN/FIL state + dirty tracking
│   ├── CmsEditModeContext.tsx     # Edit mode toggle + editor tracking
│   ├── LangContext.tsx            # Language toggle (en/fil)
│   └── ToastContext.tsx           # Toast notifications
├── pages/
│   ├── LoginPage.tsx
│   ├── CmsLandingPage.tsx
│   ├── CmsSectionPage.tsx
│   ├── CmsNewsSidebarPage.tsx
│   ├── CmsUpliftingNewsPage.tsx
│   └── CmsArticleOFWPage.tsx
├── services/
│   └── api.ts                     # Complete API client
├── types/
│   ├── api.ts                     # API response/request types
│   └── audit.ts                   # Audit log types
├── hooks/
│   ├── useFetch.ts                # Generic data fetching hook
│   ├── useCmsData.ts              # CmsDataContext wrapper
│   ├── useEditMode.ts             # CmsEditModeContext wrapper
│   └── useSortedSections.ts       # Sections with API ordering
├── lib/
│   ├── deep-set.ts                # Deep object path manipulation
│   └── motion.tsx                 # Motion/animation primitives
└── data/
    ├── section-config.ts          # Section definitions + routing
    └── mock-data.ts               # Fallback mock data
```

## Context Providers

### AuthContext
- **State**: `user` (AuthUser | null), `loading`, `isAuthenticated`
- **Methods**: `login(email, password)`, `logout()`, `refreshAuth()`
- **Token Storage**: localStorage keys:
  - `uplift-cms-access-token`
  - `uplift-cms-refresh-token`
  - `uplift-cms-user`
- **Auto-refresh**: 401 responses trigger token refresh with deduplication (single in-flight refresh)
- **On Mount**: Calls `GET /api/cms/auth/authenticate` to verify session

### CmsDataContext
- **State**: Three parallel trees:
  - `upliftValues` — Language-agnostic config/numbers
  - `upliftEN` — English content
  - `upliftFIL` — Filipino content
- **Dirty Tracking**: Set of section keys modified since last save
- **Methods**:
  - `updateField(store, path, value)` — Updates nested field via dot-path
  - `saveToApi()` — Sends only dirty sections to API
  - `resetChanges()` — Discards all changes (no re-fetch)
- **Loading**: Fetches all data on mount from CMS API

### CmsEditModeContext
- **State**: `isEditMode` (boolean), `activeEditors` (number)
- **Methods**: `setEditMode(boolean)`, `registerEditor()`, `unregisterEditor()`
- **Behavior**:
  - Toggling edit OFF discards all changes (no confirmation)
  - Sidebar navigation locked while in edit mode
  - Active editor count prevents premature exit

### LangContext
- Same as dashboard: `'en' | 'fil'` with localStorage persistence
- Key: `uplift-lang`

### ToastContext
- Provides toast notification methods (success, error, info)

## CMS Editing Components

### EditableField
- **Purpose**: Inline editing for text, numbers, URLs
- **Props**: `store` (values/en/fil), `path` (dot-path), `type` (text/textarea/number/url)
- **Behavior**:
  - View mode: shows content with pencil icon on hover
  - Edit mode: click to toggle inline editor
  - Confirm saves to CmsDataContext via `updateField()`
  - Cancel reverts to original value
- **Path Examples**: `"savingLives.title"`, `"media.newsThumbnails.savingLives[0]"`, `"fuelSupply.items[2].label"`

### EditableLinks
- **Purpose**: Array editor for buttons/links with label + URL
- **Behavior**:
  - Handles legacy single link + extraLinks array pattern
  - Add/edit/remove links inline
  - Each link has: label (text) + url (text)
  - Updates via deep-set path notation

### MediaUploadField
- **Purpose**: Image/video upload with media library browser
- **Props**: `sectionKey`, `imageKey`, `currentUrl`, `onUpload`
- **Behavior**:
  - Hover shows upload overlay
  - Click opens file picker OR media library
  - Uploads via `POST /api/cms/images/upload` or `POST /api/cms/media/upload`
  - Media library shows previously uploaded assets for the section
  - Optional thumbnail for video uploads
  - Auto-sanitizes alt text with DOMPurify

## Deep-Set Utility (src/lib/deep-set.ts)

Immutable nested object updates via dot-path:

```typescript
// Usage examples:
deepSet(obj, "savingLives.title", "New Title")
deepSet(obj, "items[0].label", "Updated Label")
deepSet(obj, "media.newsThumbnails.savingLives[2]", "https://...")
```

- Handles nested objects and arrays
- Returns new object (immutable)
- Supports bracket notation for array indices

## API Client (src/services/api.ts)

### Base URL
`VITE_CMS_API_URL` (default: http://localhost:3001)

### Authentication Endpoints
```
POST /api/cms/auth/login              → { user, accessToken, refreshToken }
GET  /api/cms/auth/authenticate       → { user }
POST /api/cms/auth/refresh            → { user, accessToken, refreshToken }
POST /api/cms/auth/logout             → void
POST /api/cms/auth/create-admin       → { user }
POST /api/cms/auth/change-password    → { message }
```

### Content Endpoints
```
GET  /api/cms/values                  → Record<sectionKey, data>
PUT  /api/cms/values/:sectionKey      → unknown
GET  /api/cms/content/:lang           → Record<sectionKey, data>
PUT  /api/cms/content/:lang/:sectionKey → unknown
GET  /api/cms/sections                → { sections: [{ key, sort_order }] }
```

### Media Endpoints
```
POST /api/cms/images/upload           → UploadedMedia
GET  /api/cms/images/:sectionKey      → { images: UploadedMedia[] }
DELETE /api/cms/images/:id            → void
POST /api/cms/media/upload            → UploadedMedia
```

### Change Request Endpoints
```
POST  /api/cms/change-requests                    → ChangeRequest
GET   /api/cms/change-requests?status=&section_key=&limit=&offset= → { changeRequests, total }
PATCH /api/cms/change-requests/:id/approve        → ChangeRequest
PATCH /api/cms/change-requests/:id/reject         → ChangeRequest
```

### Audit Log
```
GET /api/cms/audit-log?section_key=&type=&action=&limit=&offset= → { entries, total }
```

### Error Handling
- `ApiError` class with status, statusText, url
- 401 triggers automatic token refresh (except during refresh/login)
- `apiFetch()` handles headers, Bearer token, JSON serialization

## Key Types

### API Types (src/types/api.ts)
```typescript
AuthUser { id, name, email }
LoginResponse { user, accessToken, refreshToken }
ValuesRow { id, section_key, data, updated_at, updated_by }
ContentRow { id, section_key, lang, data, updated_at, updated_by }
UploadedMedia { id, section_key, image_key, blob_url, thumbnail_url, media_type, alt_text, ... }
```

### Audit Types (src/types/audit.ts)
```typescript
ChangeRequest { id, type, section_key, lang, old_data, new_data, status, submitted_*, reviewed_*, ... }
AuditLogEntry { id, action, type, section_key, lang, change_request_id, user_*, created_at }
ChangeRequestStatus = 'pending' | 'approved' | 'rejected'
AuditAction = 'submitted' | 'approved' | 'rejected'
```

## Section Config (src/data/section-config.ts)

Defines all CMS-editable sections with:
- `key` — Section key (e.g., `savingLives`)
- `route` — URL path (e.g., `/saving-lives`)
- `label` — Display name
- `icon` — Lucide icon component
- `dataKey` — Key into values/content objects

## Environment Variables

```
VITE_APP_TITLE=UPLIFT CMS
VITE_APP_ENV=development
VITE_CMS_API_URL=http://localhost:3001
```

## Edit Mode Flow

1. User clicks "Edit" in CmsToolbar
2. `isEditMode` set to true in CmsEditModeContext
3. Sidebar navigation locked (prevents leaving section while editing)
4. EditableField/EditableLinks components show edit UI
5. Changes stored in CmsDataContext (dirty tracking per section)
6. User clicks "Save" → `saveToApi()` sends only dirty sections
7. User clicks "Cancel" → `resetChanges()` discards all modifications
8. Exiting edit mode (toggling off) discards unsaved changes
