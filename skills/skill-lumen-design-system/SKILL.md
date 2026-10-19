---
name: skill-lumen-design-system
description: >
  Development companion for `@bayanichain/lumen-design-system` v1.1.0 — the org webapp design system
  by Bayanichain. React 19 + Tailwind v4 + Headless UI v2, with a flat / monochrome / typographic / minimal
  aesthetic. 19 components, 17 color tokens, Sora typography, Tailwind preset, base.css reset, usePagination hook.
  Trigger whenever the user mentions: lumen-design-system, @bayanichain/lumen-design-system, lumen design tokens,
  lumen Tailwind preset, Sora font, monochrome palette, flat design, LumenMainButton, LumenDropdownButton,
  BatchSelectButton, ContentModal, ConfirmationModal, Table, FilterBar, LumenFilter, LumenSelect, lumenSelectStyles,
  TimePeriodSelector, Pagination, usePagination, PAGE_SIZES, EnvironmentBadge, CustomToast, Spinner,
  SkeletonLoaderLines, SkeletonLoaderLinesTable, SkeletonLoaderFileCard, SkeletonLoaderPagination,
  DesignSystemShowcase, classNames helper, lumen-card, lumen-label, auth-buttons, cancel button class,
  lumen-* Tailwind tokens (bg-lumen-dark, text-lumen-muted, border-lumen-border, etc.), base.css,
  design tokens, or any work in mvp-baas-org-webapp / mvp-byc-portal-webapp / mvp-baas-authenticator-webapp /
  mvp-baas-redirect-webapp / mvp-baas-dapps that consumes this design system. Also trigger for: "make this match
  Lumen design", "use lumen components", "design tokens", "flat / sharp UI", "no rounded corners", "Bayanichain
  webapp styling", "design system PR review".
---

# Lumen Design System Skill

Companion for `@bayanichain/lumen-design-system` v1.1.0. Published to GitHub Package Registry.

## Four Design Principles (non-negotiable)

When generating, reviewing, or modifying UI code that uses this design system, **enforce these**:

1. **Flat / Sharp** — `border-radius: 0` on everything. NEVER use `rounded-*` classes. The Tailwind preset overrides `borderRadius.DEFAULT` to `0`.
2. **Monochrome** — Black, white, and grays only. Two exceptions: `lumen-error` (#ef4444), `lumen-success` (#22c55e). NO brand colors. NO gradients.
3. **Typographic** — Sora font (`font-sora`) with `-0.04em` tracking. Inter fallback. Hierarchy comes from weight + spacing, not color.
4. **Minimal** — No shadows (`shadow-*`), no gradients, no decorative chrome. Borders are 1px solid in light grays only.

**If a user (or PR) introduces `rounded-lg`, `shadow-md`, `bg-blue-500`, gradients, or a non-Lumen accent color — flag it immediately and suggest the compliant equivalent.**

## Package Exports

| Path | Content |
|------|---------|
| `@bayanichain/lumen-design-system` | Main — everything (components + tokens + hooks + helpers) |
| `@bayanichain/lumen-design-system/tokens` | `colors`, `tailwindColors`, `typography`, `spacing` |
| `@bayanichain/lumen-design-system/tailwind-preset` | Tailwind v4 preset |
| `@bayanichain/lumen-design-system/styles` | `base.css` global stylesheet |
| `@bayanichain/lumen-design-system/components` | All 19 components + types |
| `@bayanichain/lumen-design-system/helpers` | `classNames` utility |
| `@bayanichain/lumen-design-system/hooks` | `usePagination` + `PAGE_SIZES` |

## Setup in a Consuming App

```ts
// tailwind.config.ts
import lumenPreset from '@bayanichain/lumen-design-system/tailwind-preset';

export default {
  presets: [lumenPreset],
  content: [
    './src/**/*.{ts,tsx}',
    './node_modules/@bayanichain/lumen-design-system/dist/**/*.js',
  ],
};
```

```ts
// app entry (main.tsx / App.tsx) — import BEFORE app styles
import '@bayanichain/lumen-design-system/styles';
```

## Peer Dependencies (host app must provide)

```
react ^19, react-dom ^19, react-router ^7, @headlessui/react ^2,
tailwindcss ^4, clsx ^2, lucide-react >=0.400, react-select ^5,
react-toastify ^11, formik ^2
```

## Components — Quick Inventory (19 total)

| Category | Component | Purpose |
|----------|-----------|---------|
| Buttons | `LumenMainButton` | Primary/secondary button or react-router `<Link>` hybrid |
| Buttons | `LumenDropdownButton` | Button with toggle-able dropdown panel |
| Buttons | `BatchSelectButton` | Checkbox-style multi-select for lists |
| Modals | `ContentModal` | Generic modal (Headless UI Dialog) |
| Modals | `ConfirmationModal` | Pre-built confirm dialog (composes ContentModal + LumenMainButton) |
| Table | `Table` | Sortable data table with actions, empty state, skeleton overlay |
| Filters | `FilterBar` | Multi-filter bar with Apply/Reset/Export |
| Filters | `LumenFilter` | Simple text search input |
| Inputs | `LumenSelect` | Flat-styled react-select wrapper |
| Time | `TimePeriodSelector` | Preset period buttons + custom range |
| Pagination | `Pagination` | Full nav + page size + entry info (uses `usePagination`) |
| Loaders | `Spinner` | Inline SVG spinner |
| Loaders | `SkeletonLoaderLines` | 4-line pulsing skeleton |
| Loaders | `SkeletonLoaderLinesTable` | Table-shaped skeleton |
| Loaders | `SkeletonLoaderFileCard` | Card-shaped skeleton |
| Loaders | `SkeletonLoaderPagination` | Pagination-shaped skeleton |
| Toasts | `CustomToast` | react-toastify content |
| Badges | `EnvironmentBadge` | Auto-hide in PROD, "SANDBOX" in STAGING, else "TEST" |
| Showcase | `DesignSystemShowcase` | Living interactive docs (mount as a route) |

## Tokens — Quick Reference

### Core colors (use these via `bg-lumen-*` / `text-lumen-*` / `border-lumen-*`)

| Token | Hex | Typical use |
|-------|-----|-------------|
| `lumen-bg` | #fafafa | Page bg |
| `lumen-dark` | #191919 | Primary text, primary button bg |
| `lumen-charcoal` | #2C2C2C | Button hover, sidebar active |
| `lumen-medium` | #3F3F3F | Mid-tone text |
| `lumen-muted` | #777777 | Secondary text, labels |
| `lumen-subtle` | #aaaaaa | Tertiary text, hints |
| `lumen-border` | #e8e8e8 | Container borders |
| `lumen-borderLight` | #f0f0f0 | Dividers |
| `lumen-white` | #ffffff | Surfaces |
| `lumen-error` | #ef4444 | Errors only |
| `lumen-success` | #22c55e | Success only |

### Typography defaults

- Font family: `font-sora` (with Inter fallback)
- Tracking: `tracking-tight` = `-0.04em` (default)
- Scale: xs 11px / sm 12px / base 13px / md 14px / lg 18px / xl 20px
- Weights: light 300 / normal 400 / medium 500 / semibold 600 / bold 700

### Standard patterns

- Page title — `font-sora text-xl font-bold tracking-tight text-lumen-dark`
- Section heading — `font-sora text-lg font-semibold tracking-tight text-lumen-dark`
- Label — `.lumen-label` (uppercase, semibold, wide tracking, muted)
- Body — `font-sora text-[13px] font-normal tracking-tight text-lumen-dark`
- Primary button — `className="auth-buttons"` on `LumenMainButton`
- Secondary button — `className="cancel"` on `LumenMainButton`
- Card surface — `.lumen-card` (white bg, 1px border, no radius)

## Naming Conventions (enforce in PR review)

| Element | Convention | Example |
|---------|-----------|---------|
| Component files | PascalCase `.tsx` | `LumenMainButton.tsx` |
| Generic/shared components | `Lumen` prefix | `LumenMainButton`, `LumenSelect` |
| Skeleton loaders | `SkeletonLoader` prefix | `SkeletonLoaderLines` |
| Boolean props | `is*` / `has*` / `show*` | `isLoading`, `hasActions`, `showExport` |
| Handler props | `on*` | `onClose`, `onConfirm`, `onSort` |
| Style customization props | `className` / `*ClassName` | `dialogClassName`, `svgClassName` |
| CSS utility classes | kebab-case with `lumen-` prefix | `.lumen-card`, `.lumen-label` |
| Tailwind tokens | `lumen-` prefix | `bg-lumen-dark`, `text-lumen-muted` |

## Common Composition Patterns

### Filter + Table + Pagination (the most common page layout)

```tsx
<div className="flex flex-col gap-4">
  <FilterBar filters={filters} onChange={handleFilterChange}
             onApply={applyFilters} onReset={resetFilters} />
  {isFetching ? (
    <SkeletonLoaderLinesTable columnsCount={5} rowsCount={10} hasActions />
  ) : (
    <Table columns={columns} data={data} sort={sort} onSort={handleSort} actions={actions} />
  )}
  {isFetching ? (
    <SkeletonLoaderPagination />
  ) : (
    <Pagination defaultPageSize={15} dataPageCount={pageCount} totalDataCount={total} />
  )}
</div>
```

### Confirmation flow

```tsx
<ConfirmationModal
  isOpen={showConfirm}
  onClose={() => setShowConfirm(false)}
  onConfirm={async () => { await deleteItem(id); setShowConfirm(false); refetch(); }}
  isLoading={isDeleting}
  title="Delete Item"
  description="This action cannot be undone."
  confirmLabel="Delete"
/>
```

### URL-driven pagination

```tsx
const {
  pageNumber, pageSize, sortColumn, sortOrder,
  setPageNumber, setPageSize, toggleSortOrder,
} = usePagination({
  defaultPageSize: 15,
  defaultSortColumn: 'CreatedTS',
  defaultSortOrder: 'desc',
});
```

## How to Help

1. **For "build me a component / page using lumen-design-system"** — pick components from the inventory above. Use `classNames` helper for conditional classes. Default font is Sora (already applied via base.css), so don't re-specify unless overriding.

2. **For "review this PR / code"** — run the four design principles check:
   - Any `rounded-*`? Flag.
   - Any `shadow-*` or gradient? Flag.
   - Any non-`lumen-*` color (except `text-white` / `bg-white` / `text-black`)? Flag.
   - Any non-Sora font? Flag.
   - Props named `loading` instead of `isLoading`, `handleClick` instead of `onClick`? Flag.

3. **For "add a new component to the design system"** — see the deeper guidance in `references/patterns.md` (file structure, barrel exports, showcase entry, doc).

4. **For "what color/font/spacing should I use for X"** — consult `references/tokens.md` for the full token list with usage rules.

5. **For "show me the props for component X"** — see `references/components.md` (full props tables + usage examples for all 19 components + the `usePagination` hook).

## Reference Files

Three companion files in `references/` for deeper questions:

| File | Read when |
|------|-----------|
| `references/tokens.md` | Detailed color/typography/spacing tokens, Tailwind preset internals, base.css contents |
| `references/components.md` | Full props tables, prop types, usage examples for every component + usePagination |
| `references/patterns.md` | Form patterns, page layouts, naming conventions, contribution workflow, PR review checklist, decision log |
