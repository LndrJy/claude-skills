# Components Reference

All components are exported from `@bayanichain/lumen-design-system` or `@bayanichain/lumen-design-system/components`.

---

## Buttons

### LumenMainButton (`src/components/buttons/LumenMainButton.tsx`)

Versatile button/link hybrid — renders as `<button>` or react-router `<Link>` based on props.

**Props:**

| Prop | Type | Default | Description |
|------|------|---------|-------------|
| `text` | `string` | — | Button label text |
| `type` | `'button' \| 'submit' \| 'reset'` | `'button'` | HTML button type (ignored when `to` is set) |
| `className` | `string` | — | CSS class — typically `'auth-buttons'` (primary) or `'cancel'` (secondary) |
| `image` | `ReactNode` | — | Icon element rendered before text |
| `isLoading` | `boolean` | `false` | Shows Spinner and disables interaction |
| `disabled` | `boolean` | `false` | Disables button with reduced opacity |
| `to` | `string` | — | If provided, renders as react-router `<Link>` instead of `<button>` |
| `children` | `ReactNode` | — | Alternative to `text` — renders children inside the button |

**Usage:**
```tsx
// Primary button
<LumenMainButton text="Save" className="auth-buttons" />

// Secondary/cancel button
<LumenMainButton text="Cancel" className="cancel" onClick={handleCancel} />

// Link disguised as button
<LumenMainButton text="View Details" className="auth-buttons" to="/details/123" />

// With loading state
<LumenMainButton text="Saving..." className="auth-buttons" isLoading={true} />

// With icon
<LumenMainButton text="Add" className="auth-buttons" image={<PlusIcon />} />
```

**Key behavior:**
- When `to` is provided, renders `<Link>` and ignores `type`, `disabled`, `isLoading`
- When loading, shows `<Spinner>` and disables clicks
- Opacity drops to 0.6 when disabled

---

### LumenDropdownButton (`src/components/buttons/LumenDropdownButton.tsx`)

Button with a toggle-able dropdown panel below it.

**Props:**

| Prop | Type | Default | Description |
|------|------|---------|-------------|
| `label` | `string` | — | Button label text |
| `className` | `string` | — | CSS class for the button |
| `children` | `ReactNode` | — | Dropdown panel content |
| `isLoading` | `boolean` | `false` | Shows Spinner, disables button |
| `buttonType` | `'button' \| 'submit'` | `'button'` | HTML button type |

**Usage:**
```tsx
<LumenDropdownButton label="Actions" className="auth-buttons">
  <div className="p-2">
    <button onClick={handleEdit}>Edit</button>
    <button onClick={handleDelete}>Delete</button>
  </div>
</LumenDropdownButton>
```

**Key behavior:**
- Toggle on click, close on outside click
- ChevronDown icon from lucide-react rotates when open
- Dropdown is absolutely positioned below the button
- z-index: 10

---

### BatchSelectButton (`src/components/buttons/BatchSelectButton.tsx`)

Small checkbox-style button for batch selection in lists/tables.

**Props:**

| Prop | Type | Default | Description |
|------|------|---------|-------------|
| `isSelected` | `boolean` | — | Whether this item is selected |
| `onToggle` | `() => void` | — | Toggle callback |
| `disabled` | `boolean` | `false` | Hides the button completely |
| `maxSelectedItems` | `number` | — | Maximum selection count |
| `isMaxReached` | `boolean` | `false` | Whether max selection is reached |
| `onMaxReachedError` | `() => void` | — | Called when user tries to select past max |

**Usage:**
```tsx
<BatchSelectButton
  isSelected={selectedIds.includes(item.id)}
  onToggle={() => toggleSelect(item.id)}
  isMaxReached={selectedIds.length >= 10}
  maxSelectedItems={10}
  onMaxReachedError={() => toast.error('Max 10 items')}
/>
```

**Visual states:**
- Disabled: hidden (`opacity-0 pointer-events-none`)
- Unselected: white square with gray border (18x18px)
- Selected: dark background with white checkmark SVG
- Max reached (not selected): gray border, cursor changes, calls error handler on click

---

## Modals

### ContentModal (`src/components/modals/ContentModal.tsx`)

Generic modal wrapper using Headless UI `Dialog` + `Transition`.

**Props:**

| Prop | Type | Default | Description |
|------|------|---------|-------------|
| `isOpen` | `boolean` | — | Controls modal visibility |
| `children` | `ReactNode` | — | Modal content |
| `onClose` | `() => void` | — | Called on backdrop click or Escape key |
| `dialogClassName` | `string` | — | Additional classes for the dialog panel |

**Usage:**
```tsx
<ContentModal isOpen={showModal} onClose={() => setShowModal(false)}>
  <h2 className="text-lg font-semibold">Title</h2>
  <p>Content here</p>
</ContentModal>
```

**Key behavior:**
- Semi-transparent black backdrop (`bg-black/25`)
- Content panel: white bg, 1px border (#e8e8e8), max-width 700px, centered
- Scale + opacity transition on enter/leave
- Closes on Escape key or backdrop click

---

### ConfirmationModal (`src/components/modals/ConfirmationModal.tsx`)

Pre-built confirmation dialog composing `ContentModal` + `LumenMainButton`.

**Props:**

| Prop | Type | Default | Description |
|------|------|---------|-------------|
| `isOpen` | `boolean` | — | Controls visibility |
| `onClose` | `() => void` | — | Cancel/close handler |
| `onConfirm` | `() => void` | — | Confirm action handler |
| `isLoading` | `boolean` | `false` | Shows loading state on confirm button |
| `title` | `string` | — | Modal title |
| `description` | `string` | — | Explanation text |
| `confirmLabel` | `string` | `'Confirm'` | Confirm button text |
| `cancelLabel` | `string` | `'Cancel'` | Cancel button text |
| `dialogClassName` | `string` | — | Additional dialog classes |

**Usage:**
```tsx
<ConfirmationModal
  isOpen={showConfirm}
  onClose={() => setShowConfirm(false)}
  onConfirm={handleDelete}
  isLoading={isDeleting}
  title="Delete Item"
  description="Are you sure? This action cannot be undone."
  confirmLabel="Delete"
/>
```

---

## Table (`src/components/table/Table.tsx`)

Data table with sorting, custom cell rendering, row actions, and empty state.

**Props:**

| Prop | Type | Default | Description |
|------|------|---------|-------------|
| `columns` | `Column[]` | — | Column definitions |
| `data` | `Record<string, any>[]` | — | Row data array |
| `actions` | `Action[]` | — | Row action buttons/links |
| `onSort` | `(column: string \| string[]) => void` | — | Sort handler |
| `sort` | `{ column: string \| string[], order: 'asc' \| 'desc' }` | — | Current sort state |
| `isFetching` | `boolean` | `false` | Shows skeleton loader overlay |

**Column interface:**
```typescript
interface Column {
  key: string | string[];    // Data key (supports nested: ['user', 'name'])
  label: string;             // Column header text
  sortable?: boolean;        // Enable sorting
  render?: (value: any, row: any) => ReactNode;  // Custom cell renderer
}
```

**Action interface:**
```typescript
interface Action {
  label: string;
  onClick?: (row: any) => void;  // Button action
  to?: (row: any) => string;     // Link action (react-router)
}
```

**Usage:**
```tsx
<Table
  columns={[
    { key: 'name', label: 'Name', sortable: true },
    { key: 'status', label: 'Status', render: (val) => <Badge>{val}</Badge> },
    { key: ['user', 'email'], label: 'Email', sortable: true },
  ]}
  data={items}
  actions={[
    { label: 'View', to: (row) => `/items/${row.id}` },
    { label: 'Delete', onClick: (row) => handleDelete(row.id) },
  ]}
  sort={sort}
  onSort={handleSort}
/>
```

**Key behavior:**
- Always renders 10 rows height (filler rows for short data)
- Sort icons: ascending/descending arrows in table headers
- Hover effect on data rows
- Empty state when data is empty array
- Supports nested key access (e.g., `['user', 'name']` accesses `row.user.name`)

---

## Filters

### FilterBar (`src/components/filters/FilterBar.tsx`)

Multi-filter bar with react-select dropdowns, Apply/Reset buttons, and optional Export.

**Props:**

| Prop | Type | Default | Description |
|------|------|---------|-------------|
| `filters` | `Filter[]` | — | Filter definitions |
| `onChange` | `(key: string, value: any) => void` | — | Filter value change handler |
| `onApply` | `() => void` | — | Apply filters handler |
| `onReset` | `() => void` | — | Reset all filters handler |
| `onExport` | `() => void` | — | Export action handler |
| `isLoading` | `boolean` | `false` | Disables interactions |
| `showExport` | `boolean` | `false` | Shows export button |

**Filter interface:**
```typescript
interface Filter {
  key: string;
  label: string;
  options: { value: string; label: string }[];
  value: any;
  placeholder?: string;
}
```

**Usage:**
```tsx
<FilterBar
  filters={[
    { key: 'status', label: 'Status', options: statusOptions, value: selectedStatus },
    { key: 'type', label: 'Type', options: typeOptions, value: selectedType },
  ]}
  onChange={(key, value) => setFilter(key, value)}
  onApply={applyFilters}
  onReset={resetFilters}
  showExport
  onExport={exportData}
/>
```

---

### LumenFilter (`src/components/filters/LumenFilter.tsx`)

Simple text search input field.

**Props:**

| Prop | Type | Default | Description |
|------|------|---------|-------------|
| `search` | `string` | — | Current search value |
| `setSearch` | `(value: string) => void` | — | Search value setter |
| `placeholder` | `string` | `'Search'` | Input placeholder |

**Usage:**
```tsx
<LumenFilter search={query} setSearch={setQuery} placeholder="Search files..." />
```

---

## Loaders

### Spinner (`src/components/loaders/Spinner.tsx`)

Inline SVG loading spinner with CSS animation.

**Props:**

| Prop | Type | Default | Description |
|------|------|---------|-------------|
| `svgClassName` | `string` | — | SVG sizing class (e.g., `'h-5 w-5'`) |

**Usage:**
```tsx
<Spinner />
<Spinner svgClassName="h-8 w-8" />
```

---

### SkeletonLoaderLines (`src/components/loaders/SkeletonLoaderLines.tsx`)

Pulsing skeleton lines for text content loading. Renders 4 animated lines.

**Usage:**
```tsx
<SkeletonLoaderLines />
```

---

### SkeletonLoaderLinesTable (`src/components/loaders/SkeletonLoaderLinesTable.tsx`)

Table-shaped skeleton loader.

**Props:**

| Prop | Type | Default | Description |
|------|------|---------|-------------|
| `columnsCount` | `number` | — | Number of columns to render |
| `rowsCount` | `number` | — | Number of rows to render |
| `hasActions` | `boolean` | `false` | Whether to show an actions column |

**Usage:**
```tsx
<SkeletonLoaderLinesTable columnsCount={5} rowsCount={10} hasActions />
```

---

### SkeletonLoaderFileCard (`src/components/loaders/SkeletonLoaderFileCard.tsx`)

Card-shaped skeleton with header and content area for file preview loading.

**Usage:**
```tsx
<SkeletonLoaderFileCard />
```

---

### SkeletonLoaderPagination (`src/components/loaders/SkeletonLoaderPagination.tsx`)

Skeleton matching the Pagination component layout (info text + page buttons + dropdown).

**Usage:**
```tsx
<SkeletonLoaderPagination />
```

---

## Toasts

### CustomToast (`src/components/toasts/CustomToast.tsx`)

Toast notification component designed for use with react-toastify.

**Props:**

| Prop | Type | Default | Description |
|------|------|---------|-------------|
| `message` | `string` | — | Primary toast message |
| `subMessage` | `string` | — | Secondary/detail message |
| `icon` | `ReactNode` | — | Icon element |

**Usage:**
```tsx
import { toast } from 'react-toastify';

toast(<CustomToast message="Saved!" subMessage="Changes applied" icon={<CheckIcon />} />);
```

---

## Badges

### EnvironmentBadge (`src/components/badges/EnvironmentBadge.tsx`)

Environment indicator badge that auto-hides in production.

**Props:**

| Prop | Type | Default | Description |
|------|------|---------|-------------|
| `position` | `string` | `'fixed top-4 right-4'` | CSS position classes |
| `className` | `string` | — | Additional CSS classes |
| `mode` | `string` | — | Server mode: `'DEV'`, `'TEST'`, `'STAGING'`, `'PROD'` |

**Behavior by mode:**
- `PROD` → hidden (returns `null`)
- `STAGING` → shows "SANDBOX"
- All others → shows "TEST"

**Usage:**
```tsx
<EnvironmentBadge mode={import.meta.env.VITE_SERVER_MODE} />
```

---

## Inputs

### LumenSelect (`src/components/inputs/LumenSelect.tsx`)

Styled react-select wrapper with Lumen flat design.

**Props:**

| Prop | Type | Default | Description |
|------|------|---------|-------------|
| `value` | `Option \| null` | — | Selected option |
| `onChange` | `(option: Option \| null) => void` | — | Change handler |
| `options` | `Option[]` | — | Available options |
| `placeholder` | `string` | `'Select...'` | Placeholder text |
| `isLoading` | `boolean` | `false` | Shows loading indicator |
| `isClearable` | `boolean` | `false` | Allows clearing selection |
| `isSearchable` | `boolean` | `true` | Enables type-to-search |
| `isDisabled` | `boolean` | `false` | Disables interaction |
| `className` | `string` | — | Container CSS classes |
| `label` | `string` | — | Optional label above the select |

**Option type:**
```typescript
interface Option {
  value: string;
  label: string;
}
```

**Exported extras:**
- `lumenSelectStyles` — The custom styles object, for use in standalone react-select instances

**Usage:**
```tsx
<LumenSelect
  label="Environment"
  value={selectedEnv}
  onChange={setSelectedEnv}
  options={[
    { value: 'dev', label: 'Development' },
    { value: 'staging', label: 'Staging' },
    { value: 'prod', label: 'Production' },
  ]}
  isClearable
/>
```

---

## Time Period

### TimePeriodSelector (`src/components/time-period/TimePeriodSelector.tsx`)

Preset time period buttons with optional custom date range.

**Props:**

| Prop | Type | Default | Description |
|------|------|---------|-------------|
| `options` | `TimePeriodOption[]` | — | Preset period buttons |
| `selectedTimePeriod` | `string` | — | Currently selected period value |
| `onChangeCustom` | `(value: string) => void` | — | Period selection handler |
| `onCustomClick` | `() => void` | — | Custom date picker trigger |
| `onResetCustom` | `() => void` | — | Clear custom range |
| `customLabel` | `string` | — | Label when custom range is active (e.g., "Mar 1 - Mar 15") |
| `isLoading` | `boolean` | `false` | Disables interactions |

**TimePeriodOption type:**
```typescript
interface TimePeriodOption {
  label: string;   // Display text (e.g., "24H", "7D", "30D")
  value: string;   // Value identifier
}
```

**Usage:**
```tsx
<TimePeriodSelector
  options={[
    { label: '24H', value: '24h' },
    { label: '7D', value: '7d' },
    { label: '30D', value: '30d' },
    { label: 'All', value: 'all' },
  ]}
  selectedTimePeriod={period}
  onChangeCustom={setPeriod}
  onCustomClick={() => setShowDatePicker(true)}
  onResetCustom={() => setCustomRange(null)}
  customLabel={customRange ? `${customRange.start} - ${customRange.end}` : ''}
/>
```

---

## Pagination

### Pagination (`src/components/pagination/Pagination.tsx`)

Full pagination control with page navigation, size selector, and entry info.

**Props:**

| Prop | Type | Default | Description |
|------|------|---------|-------------|
| `defaultPageSize` | `number` | — | Initial page size |
| `dataPageCount` | `number` | — | Total number of pages |
| `totalDataCount` | `number` | — | Total number of entries |

**Usage:**
```tsx
<Pagination
  defaultPageSize={15}
  dataPageCount={Math.ceil(totalCount / pageSize)}
  totalDataCount={totalCount}
/>
```

**Features:**
- First / Previous / Next / Last navigation buttons
- Numbered page buttons (max 10 visible, centered on current page)
- Page size dropdown via Headless UI Listbox (options: 10, 15, 30, 50, 100)
- "Showing X to Y of Z entries" info text
- Uses `usePagination` hook — state lives in URL search params

**Constants:**
- `MAX_RENDERED_PAGES`: 10
- `PAGE_START_OFFSET`: 5

---

## Hooks

### usePagination (`src/hooks/usePagination.ts`)

URL-based pagination state management using react-router's `useSearchParams`.

**Props:**

| Prop | Type | Default | Description |
|------|------|---------|-------------|
| `defaultPageSize` | `number` | — | Initial page size |
| `defaultSortColumn` | `string` | — | Initial sort column |
| `defaultSortOrder` | `string` | — | Initial sort direction |

**Returns:**

| Value | Type | Description |
|-------|------|-------------|
| `pageNumber` | `number` | Current page (1-based) |
| `pageSize` | `number` | Items per page |
| `pageSizeItem` | `Option` | Current page size as select option |
| `sortColumn` | `string` | Current sort column |
| `sortOrder` | `string` | Current sort direction |
| `setPageNumber` | `(n: number) => void` | Page setter |
| `setPageSize` | `(n: number) => void` | Page size setter |
| `setSortColumn` | `(col: string) => void` | Sort column setter |
| `setSortOrder` | `(order: string) => void` | Sort order setter |
| `toggleSortOrder` | `() => void` | Toggle asc/desc |

**Exported constants:**
- `PAGE_SIZES`: `[{ value: '10', label: '10' }, { value: '15', label: '15' }, { value: '30', label: '30' }, { value: '50', label: '50' }, { value: '100', label: '100' }]`

**Usage:**
```tsx
const {
  pageNumber, pageSize, sortColumn, sortOrder,
  setPageNumber, setPageSize, toggleSortOrder
} = usePagination({
  defaultPageSize: 15,
  defaultSortColumn: 'CreatedTS',
  defaultSortOrder: 'desc',
});
```

---

## Helpers

### classNames (`src/helpers/classNames.ts`)

Simple utility for merging CSS class strings, filtering out falsy values.

**Usage:**
```tsx
import { classNames } from '@bayanichain/lumen-design-system';

<div className={classNames(
  'base-class',
  isActive && 'active-class',
  isDisabled && 'disabled-class',
  undefined,  // filtered out
  '',          // filtered out
)} />
```

---

## Showcase

### DesignSystemShowcase (`src/components/showcase/DesignSystemShowcase.tsx`)

Interactive component documentation and live demo tool.

**Props:**

| Prop | Type | Default | Description |
|------|------|---------|-------------|
| `title` | `string` | — | Page title displayed at the top |

**Features:**
- Sidebar navigation with all design system sections
- Live component demos with interactive state
- Color swatches with hex values
- Typography specimens
- Spacing visualizations
- DO/DON'T rules for each category
- Sections: Colors, Typography, Spacing, Borders, Buttons, Inputs, Select, Table, Modals, Filters, Time Period, Batch Select, Pagination, Loaders, Toasts, Badges, Cards

**Usage:**
```tsx
// Typically mounted as a route in the consuming app
<DesignSystemShowcase title="Lumen Design System" />
```

This component imports and demonstrates ALL other components — it's the living documentation.
