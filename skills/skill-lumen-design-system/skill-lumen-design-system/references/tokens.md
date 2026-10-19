# Design Tokens Reference

## Colors (`src/tokens/colors.ts`)

### Core Palette (9 tokens)

| Token | Hex | Tailwind Class | Usage |
|-------|-----|---------------|-------|
| `bg` | `#fafafa` | `bg-lumen-bg` | Page background, app shell |
| `dark` | `#191919` | `bg-lumen-dark`, `text-lumen-dark` | Primary text, active elements, primary buttons |
| `charcoal` | `#2C2C2C` | `bg-lumen-charcoal`, `text-lumen-charcoal` | Sidebar active state, button hover |
| `medium` | `#3F3F3F` | `text-lumen-medium` | Mid-tone text, secondary headings |
| `muted` | `#777777` | `text-lumen-muted` | Secondary text, labels, metadata |
| `subtle` | `#aaaaaa` | `text-lumen-subtle` | Tertiary text, placeholders, hints |
| `border` | `#e8e8e8` | `border-lumen-border` | Container borders, card edges, modal outlines |
| `borderLight` | `#f0f0f0` | `border-lumen-borderLight` | Dividers, table row separators, light lines |
| `white` | `#ffffff` | `bg-lumen-white` | Card surfaces, modal backgrounds, input fills |

### Extended Palette (6 tokens)

| Token | Hex | Tailwind Class | Usage |
|-------|-----|---------------|-------|
| `inputBorder` | `#e0e0e0` | `border-lumen-inputBorder` | Input field borders (slightly darker than `border`) |
| `cardBorder` | `#eeeeee` | `border-lumen-cardBorder` | Card-specific borders (slightly lighter than `border`) |
| `disabled` | `#f5f5f5` | `bg-lumen-disabled` | Disabled element backgrounds |
| `placeholder` | `#c0c0c0` | `text-lumen-placeholder` | Input placeholder text |
| `paginationText` | `#585858` | `text-lumen-paginationText` | Pagination info text |
| `controlDisabled` | `#cccccc` | `text-lumen-controlDisabled` | Disabled control text/icons |

### State Colors (2 tokens)

| Token | Hex | Tailwind Class | Usage |
|-------|-----|---------------|-------|
| `error` | `#ef4444` | `text-lumen-error`, `border-lumen-error` | Error messages, validation borders, destructive actions |
| `success` | `#22c55e` | `text-lumen-success`, `bg-lumen-success` | Success states, environment badge indicator dot |

### Color Usage Rules

1. **Never use color for decoration** — only for semantic meaning (error, success) or text hierarchy
2. **Text hierarchy**: `dark` → `charcoal` → `medium` → `muted` → `subtle` → `placeholder`
3. **Border hierarchy**: `inputBorder` (interactive) → `border` (containers) → `borderLight` (dividers) → `cardBorder` (cards)
4. **Background hierarchy**: `white` (surfaces) → `bg` (page) → `disabled` (non-interactive)
5. **Primary buttons**: `bg-lumen-dark text-white` → hover: `bg-lumen-charcoal`
6. **Cancel/secondary buttons**: transparent with border → hover: `bg-gray-50`

### Tailwind Color Mapping

The `tailwindColors` export maps all tokens into a Tailwind-compatible format:

```typescript
export const tailwindColors = {
  lumen: {
    bg: '#fafafa',
    dark: '#191919',
    charcoal: '#2C2C2C',
    medium: '#3F3F3F',
    muted: '#777777',
    subtle: '#aaaaaa',
    border: '#e8e8e8',
    borderLight: '#f0f0f0',
    white: '#ffffff',
    inputBorder: '#e0e0e0',
    cardBorder: '#eeeeee',
    disabled: '#f5f5f5',
    placeholder: '#c0c0c0',
    paginationText: '#585858',
    controlDisabled: '#cccccc',
    error: '#ef4444',
    success: '#22c55e',
  },
};
```

---

## Typography (`src/tokens/typography.ts`)

### Font Families

| Token | Value | Tailwind Class | Usage |
|-------|-------|---------------|-------|
| `primary` | `'Sora', 'Inter', sans-serif` | `font-sora` | Headings, buttons, labels, primary text |
| `fallback` | `'Inter', sans-serif` | `font-inter` | Body text, data tables, secondary content |

Both fonts are imported from Google Fonts in `base.css`:
```css
@import url('https://fonts.googleapis.com/css2?family=Inter:wght@300;400;500;600;700&family=Sora:wght@300;400;500;600;700&display=swap');
```

### Font Size Scale

| Token | Value | Usage |
|-------|-------|-------|
| `xs` | `11px` | Fine print, tertiary metadata |
| `sm` | `12px` | Labels, badges, table headers, secondary text |
| `base` | `13px` | Body text, table cells, form inputs |
| `md` | `14px` | Slightly larger body, button text |
| `lg` | `18px` | Section headings, modal titles |
| `xl` | `20px` | Page titles, major headings |

### Font Weights

| Token | Value | Usage |
|-------|-------|-------|
| `light` | `300` | Decorative text, large display numbers |
| `normal` | `400` | Body text, table cells |
| `medium` | `500` | Emphasized body, button text, active states |
| `semibold` | `600` | Section headings, modal titles, labels |
| `bold` | `700` | Page titles, major headings |

### Letter Spacing

| Token | Value | Usage |
|-------|-------|-------|
| `tight` | `-0.04em` | Default for Sora font — most headings and body text |
| `snug` | `-0.02em` | Slightly looser, used for medium-length text |
| `wide` | `0.07em` | Uppercase labels (e.g., `.lumen-label`) |
| `wider` | `0.08em` | Table headers, filter labels |
| `widest` | `0.1em` | Section dividers, all-caps decorative text |

### Line Height

| Token | Value | Usage |
|-------|-------|-------|
| `normal` | `1.4em` | Body text, descriptions |
| `compact` | `1.2em` | Buttons, badges, single-line elements |
| `tight` | `1.3em` | Table cells, form labels |

### Typography Patterns

- **Page title**: `font-sora text-xl font-bold tracking-tight text-lumen-dark`
- **Section heading**: `font-sora text-lg font-semibold tracking-tight text-lumen-dark`
- **Label**: `font-sora text-sm font-semibold tracking-wide uppercase text-lumen-muted` (`.lumen-label` class)
- **Body**: `font-sora text-[13px] font-normal tracking-tight text-lumen-dark`
- **Secondary text**: `font-sora text-sm font-normal text-lumen-muted`
- **Table header**: `font-sora text-sm font-semibold tracking-wider uppercase text-lumen-muted`

---

## Spacing (`src/tokens/spacing.ts`)

### Base Scale

| Index | Value | Usage |
|-------|-------|-------|
| `0` | `0px` | No spacing |
| `1` | `2px` | Micro gap (icon adjustments) |
| `2` | `4px` | Tight gap (between inline elements) |
| `3` | `8px` | Small gap (icon-to-text, compact lists) |
| `4` | `12px` | Medium gap (form field padding, table cells) |
| `5` | `14px` | Medium-large gap (filter padding) |
| `6` | `16px` | Standard gap (section spacing, table cell padding) |
| `7` | `20px` | Large gap (button padding, card vertical padding) |
| `8` | `24px` | XL gap (modal padding, card horizontal padding, form field gap) |

### Semantic Spacing Tokens

| Token | Value | Usage |
|-------|-------|-------|
| `inputPaddingX` | `12px` | Horizontal padding inside inputs |
| `inputHeight` | `40px` | Standard input/select height |
| `buttonPaddingX` | `20px` | Horizontal padding inside buttons |
| `buttonHeight` | `40px` | Standard button height |
| `cardPaddingX` | `24px` | Card horizontal padding |
| `cardPaddingY` | `20px` | Card vertical padding |
| `filterPaddingX` | `20px` | Filter bar horizontal padding |
| `filterPaddingY` | `14px` | Filter bar vertical padding |
| `tableCellPaddingX` | `16px` | Table cell horizontal padding |
| `tableCellPaddingY` | `12px` | Table cell vertical padding |
| `sectionGap` | `16px` | Gap between sections |
| `modalPadding` | `24px` | Modal content padding |
| `formFieldGap` | `24px` | Gap between form fields |
| `buttonGroupGap` | `24px` | Gap between button groups |
| `iconGap` | `8px` | Gap between icon and text |

---

## Tailwind Preset (`src/tailwind-preset/index.ts`)

The Tailwind preset extends the default configuration with Lumen tokens:

### What it adds
- **Colors**: All 17 `lumen-*` color utilities
- **Font Families**: `font-sora` and `font-inter`
- **Letter Spacing**: `tracking-tight` through `tracking-widest` with Lumen values
- **Line Height**: `leading-normal`, `leading-compact`, `leading-tight`

### What it overrides
- **Border Radius**: `borderRadius: { DEFAULT: '0' }` — forces all `rounded-*` utilities to `0`

### How to use in consuming app

```typescript
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

**Important**: Include the design system's dist files in `content` so Tailwind generates classes used by the components.

---

## Base CSS (`src/styles/base.css`)

### What it provides

1. **Google Fonts import** — Sora + Inter with all needed weights (300-700)
2. **Global resets** — `html`, `body` get `bg-lumen-bg`, Sora font, tight tracking
3. **Heading resets** — `h1`-`h6` get Sora font with semibold/bold weights
4. **Input styling** — All inputs, selects, textareas get `border-radius: 0`, consistent borders
5. **Checkbox/radio** — Custom flat styling
6. **Utility classes**:
   - `.auth-buttons` — Primary button style (dark bg, white text, hover to charcoal)
   - `.cancel` — Secondary/ghost button style (transparent, border, hover gray)
   - `.lumen-card` — Card container (white bg, 1px border, no radius)
   - `.lumen-label` — Uppercase label (semibold, wide tracking, muted color)
   - `.custom-container-filter` — Filter bar wrapper
   - `.custom-toast` — Toast notification styling
7. **Scrollbar styling** — Thin, light gray scrollbars

### How to import

```typescript
// In your app's entry file (e.g., main.tsx or App.tsx)
import '@bayanichain/lumen-design-system/styles';
```

This must be imported **before** your app's Tailwind styles to establish base resets.
