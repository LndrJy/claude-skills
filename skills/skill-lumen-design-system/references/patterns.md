# Patterns & Governance Reference

## Design Patterns

### Form Patterns

**Standard Form Layout:**
- Vertical stack with `formFieldGap` (24px) between fields
- Labels above inputs: `.lumen-label` class (uppercase, semibold, wide tracking, muted)
- Inputs: full width, 40px height, 1px border, 0 border-radius
- Error messages: `text-lumen-error text-sm` below the input
- Submit button: `LumenMainButton` with `className="auth-buttons"` at bottom
- Cancel button: `LumenMainButton` with `className="cancel"` beside submit

**Form Field Pattern:**
```tsx
<div className="flex flex-col gap-1">
  <label className="lumen-label">Field Name</label>
  <input className="w-full h-[40px] px-3 border border-lumen-inputBorder text-[13px] font-sora" />
  {error && <span className="text-lumen-error text-sm">{error}</span>}
</div>
```

**Form with Formik:**
- Use `formik` for form state management (peer dependency)
- Zod for validation schemas
- Connect fields via `formik.values`, `formik.handleChange`, `formik.errors`

**Modal Forms:**
- Use `ContentModal` wrapper
- Form content as children
- Submit/Cancel in a button group at bottom with `buttonGroupGap` (24px) between them

### Data Display Patterns

**Table Page Layout:**
```
┌─────────────────────────────────────┐
│ Page Title (text-xl font-bold)      │
├─────────────────────────────────────┤
│ FilterBar / LumenFilter             │
├─────────────────────────────────────┤
│ Table                               │
│  ┌──────┬──────┬──────┬────────┐   │
│  │ Col1 │ Col2 │ Col3 │ Actions│   │
│  ├──────┼──────┼──────┼────────┤   │
│  │ ...  │ ...  │ ...  │ View   │   │
│  └──────┴──────┴──────┴────────┘   │
├─────────────────────────────────────┤
│ Pagination                          │
└─────────────────────────────────────┘
```

**Loading States:**
- Table loading: `SkeletonLoaderLinesTable` with matching column/row count
- Card loading: `SkeletonLoaderFileCard`
- Text loading: `SkeletonLoaderLines`
- Pagination loading: `SkeletonLoaderPagination`
- Inline loading: `Spinner` inside buttons/cells

**Empty States:**
- Table: built-in empty state (renders "No data" in the table body)
- Custom: centered text with muted color

**Sort Pattern:**
```tsx
const [sort, setSort] = useState({ column: 'name', order: 'asc' });

const handleSort = (column) => {
  setSort(prev => ({
    column,
    order: prev.column === column && prev.order === 'asc' ? 'desc' : 'asc',
  }));
};

<Table columns={columns} data={data} sort={sort} onSort={handleSort} />
```

### Page Layout Patterns

**Standard Page:**
```tsx
<div className="flex flex-col gap-4 p-6">
  <h1 className="font-sora text-xl font-bold tracking-tight text-lumen-dark">
    Page Title
  </h1>
  {/* Content sections with sectionGap (16px) between them */}
</div>
```

**Card Layout:**
```tsx
<div className="lumen-card">
  <div className="p-6">
    <h2 className="font-sora text-lg font-semibold tracking-tight mb-4">Card Title</h2>
    {/* Card content */}
  </div>
</div>
```

**Filter + Table + Pagination (most common pattern):**
```tsx
<div className="flex flex-col gap-4">
  <FilterBar filters={filters} onChange={handleFilterChange} onApply={applyFilters} onReset={resetFilters} />
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

**Confirmation Flow:**
```tsx
// 1. User clicks delete button → open modal
// 2. ConfirmationModal shows with description
// 3. User confirms → isLoading=true → API call → close modal + refresh data
// 4. User cancels → close modal
<ConfirmationModal
  isOpen={showConfirm}
  onClose={() => setShowConfirm(false)}
  onConfirm={async () => {
    await deleteItem(selectedId);
    setShowConfirm(false);
    refetchData();
  }}
  isLoading={isDeleting}
  title="Delete Item"
  description="This action cannot be undone."
  confirmLabel="Delete"
/>
```

---

## Naming Conventions

### File Naming

| Type | Convention | Example |
|------|-----------|---------|
| React components | PascalCase `.tsx` | `LumenMainButton.tsx`, `ContentModal.tsx` |
| Token files | camelCase `.ts` | `colors.ts`, `typography.ts` |
| Hook files | camelCase with `use` prefix `.ts` | `usePagination.ts` |
| Helper files | camelCase `.ts` | `classNames.ts` |
| Barrel exports | `index.ts` | Every directory has one |
| Documentation | kebab-case `.md` | `naming-conventions.md`, `form-patterns.md` |
| Component directories | kebab-case | `time-period/`, `loaders/` |

### Component Naming

| Pattern | When to use | Examples |
|---------|------------|---------|
| `Lumen` prefix | Shared/generic components used across apps | `LumenMainButton`, `LumenSelect`, `LumenFilter`, `LumenDropdownButton` |
| Descriptive name | Specific-purpose components | `ContentModal`, `ConfirmationModal`, `FilterBar`, `Table`, `Pagination` |
| `SkeletonLoader` prefix | Loading skeleton variants | `SkeletonLoaderLines`, `SkeletonLoaderLinesTable`, `SkeletonLoaderFileCard` |
| `Custom` prefix | Customized third-party wrappers | `CustomToast` |
| `Environment` prefix | Environment-aware components | `EnvironmentBadge` |
| `BatchSelect` prefix | Batch operation components | `BatchSelectButton` |

### Props Naming

| Pattern | Convention | Examples |
|---------|-----------|---------|
| Boolean state | `is` prefix | `isLoading`, `isOpen`, `isSelected`, `isDisabled`, `isClearable`, `isSearchable`, `isMaxReached` |
| Boolean feature | `show`/`has` prefix | `showExport`, `hasActions` |
| Event handlers | `on` prefix | `onClose`, `onConfirm`, `onToggle`, `onChange`, `onSort`, `onApply`, `onReset`, `onExport` |
| CSS customization | `className` or `*ClassName` | `className`, `dialogClassName`, `svgClassName` |
| Content | descriptive noun | `title`, `description`, `label`, `message`, `subMessage`, `text`, `placeholder` |
| Data | descriptive noun | `data`, `columns`, `options`, `filters`, `value`, `sort` |
| Counts | descriptive noun | `columnsCount`, `rowsCount`, `totalDataCount`, `dataPageCount`, `maxSelectedItems` |

### CSS Class Naming

| Pattern | Examples |
|---------|---------|
| `lumen-*` for design system classes | `.lumen-card`, `.lumen-label` |
| `auth-buttons` for primary button style | `.auth-buttons` |
| `cancel` for secondary button style | `.cancel` |
| `custom-*` for customized third-party | `.custom-container-filter`, `.custom-toast` |
| Tailwind `lumen-*` for token colors | `bg-lumen-dark`, `text-lumen-muted`, `border-lumen-border` |

---

## Contribution Guide

### Adding a New Component

1. **Choose the right directory** — group by function:
   - `buttons/` — clickable actions
   - `modals/` — overlay dialogs
   - `inputs/` — form controls
   - `loaders/` — loading states
   - `filters/` — data filtering
   - `badges/` — status indicators
   - New category if none fits

2. **Create the component file**:
   ```
   src/components/{category}/{ComponentName}.tsx
   ```

3. **Follow the props pattern**:
   - Export the props interface: `export interface ComponentNameProps { ... }`
   - Use `is*` for booleans, `on*` for handlers
   - Accept `className` for style customization
   - Use `classNames` helper for conditional classes

4. **Enforce design principles**:
   - No `rounded-*` classes (border-radius is 0 globally)
   - No `shadow-*` classes
   - No colored backgrounds (only `lumen-dark` for primary buttons, `white` for surfaces)
   - Use only `lumen-*` color tokens
   - Font should be Sora (`font-sora`) by default

5. **Export from barrels**:
   - Add to `src/components/index.ts`
   - Add to `src/index.ts`
   - Export both the component and its props interface

6. **Add to DesignSystemShowcase**:
   - Add a new section in `DesignSystemShowcase.tsx`
   - Include live demo with interactive state
   - Show usage code example

7. **Write documentation**:
   - Add or update the relevant file in `docs/02-components/`
   - Include: description, props table, usage examples, DO/DON'T rules

### Adding a New Token

1. Add the token value to the relevant file in `src/tokens/`
2. If it's a color, add to both `colors` and `tailwindColors` objects
3. If it should be available in Tailwind, update `src/tailwind-preset/index.ts`
4. Export from `src/tokens/index.ts`
5. Update the relevant documentation in `docs/01-foundations/`
6. Add a swatch/specimen to `DesignSystemShowcase`

### PR Review Checklist

When reviewing design system PRs, verify:

- [ ] **Flat design**: No `rounded-*`, no `shadow-*`, no gradients anywhere
- [ ] **Monochrome**: Only `lumen-*` colors used, no brand/accent colors
- [ ] **Typography**: Sora font with appropriate weight/tracking
- [ ] **Spacing**: Uses semantic spacing tokens, not arbitrary values
- [ ] **Props naming**: Follows `is*`/`on*`/`className` conventions
- [ ] **Barrel exports**: Component and types exported from `index.ts` files
- [ ] **Peer dependencies**: No new hard dependencies — use peer deps for external packages
- [ ] **TypeScript**: Props interface exported, strict types (no `any` in public API)
- [ ] **Showcase**: New component has a section in `DesignSystemShowcase`
- [ ] **Documentation**: Usage guide in `docs/02-components/`

### Decision Log (Key Decisions)

Reference `docs/04-governance/decision-log.md` for the full log. Key decisions:

- **React 19**: Peer dependency targets React 19.0.0+ (latest stable)
- **Tailwind v4**: Uses Tailwind CSS v4 with preset-based configuration
- **Headless UI v2**: For accessible modal/listbox primitives
- **react-select v5**: For complex select/filter dropdowns
- **react-router v7**: For Link component and URL-based hooks
- **No Storybook**: DesignSystemShowcase serves as the living documentation instead
- **No CSS-in-JS**: Tailwind + base.css approach for all styling
- **TypeScript strict mode**: All components must be strictly typed
- **GitHub Packages**: Published to npm.pkg.github.com under @bayanichain scope
