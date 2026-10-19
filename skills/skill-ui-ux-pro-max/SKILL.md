---
name: skill-ui-ux-pro-max
description: >
  AI-powered design intelligence toolkit — 67 UI styles, 161 color palettes, 57 font pairings, 99 UX guidelines,
  25 chart types, logo generation (55 styles, Gemini AI), corporate identity program (50 deliverables), HTML
  presentations (Chart.js), banner design (22 styles), icon design (15 styles, SVG), social photos (multi-platform).
  Trigger for: UI design, UX guidelines, design system creation, color palette, typography, font pairings, logo design,
  CIP mockups, brand identity, banner design, social media images, icon generation, design tokens, Tailwind theming,
  shadcn/ui styling, accessibility, chart recommendations, landing page design, slide/pitch deck creation.
  Also trigger when user says "design this", "style guide", "color scheme", "logo", "banner", "social post",
  "brand identity", "design system", "UI style", "icon set", or any visual/design task.
---

# UI/UX Pro Max Skill

AI-powered design intelligence toolkit by NextLevelBuilder (v2.5.0).

**Source repo:** `C:\Users\irent\OneDrive\Documents\GitHub\ui-ux-pro-max-skill`

## Setup

```bash
export GEMINI_API_KEY="your-key"  # https://aistudio.google.com/apikey
pip install google-genai pillow
```

## Sub-skills

This wraps 5 sub-skills from the source repo:

| Sub-skill | Source | Purpose |
|-----------|--------|---------|
| **design** (main) | `.claude/skills/design/SKILL.md` | Unified router — logo, CIP, slides, banners, icons, social photos |
| **brand** | `.claude/skills/brand/SKILL.md` | Brand voice, visual identity, messaging, asset management |
| **design-system** | `.claude/skills/design-system/SKILL.md` | Token architecture, component specs, CSS vars, Tailwind themes |
| **banner-design** | `.claude/skills/banner-design/SKILL.md` | Banner design for social, ads, web, print |
| **slides** | `.claude/skills/slides/SKILL.md` | HTML presentations with Chart.js |

## How to Use

When a design task comes in, read the relevant sub-skill SKILL.md from the source repo:

```
C:\Users\irent\OneDrive\Documents\GitHub\ui-ux-pro-max-skill\.claude\skills\{sub-skill}\SKILL.md
```

### Search (BM25 + regex hybrid)

```bash
REPO="C:/Users/irent/OneDrive/Documents/GitHub/ui-ux-pro-max-skill"

# Domain search
python3 "$REPO/src/ui-ux-pro-max/scripts/search.py" "<query>" --domain <domain> [-n <max>]
# Domains: product, style, typography, color, landing, chart, ux

# Stack-specific search
python3 "$REPO/src/ui-ux-pro-max/scripts/search.py" "<query>" --stack <stack>
# Stacks: html-tailwind, react, nextjs, astro, vue, nuxtjs, nuxt-ui, svelte, swiftui, react-native, flutter, shadcn, jetpack-compose
```

### Logo Generation

```bash
python3 "$REPO/.claude/skills/design/scripts/logo/search.py" "tech startup modern" --design-brief -p "BrandName"
python3 "$REPO/.claude/skills/design/scripts/logo/generate.py" --brand "TechFlow" --style minimalist --industry tech
```

### CIP Mockups

```bash
python3 "$REPO/.claude/skills/design/scripts/cip/generate.py" --brand "TopGroup" --logo /path/to/logo.png --industry "consulting" --set
```

### Icon Generation

```bash
python3 "$REPO/.claude/skills/design/scripts/icon/generate.py" --prompt "settings gear" --style outlined
python3 "$REPO/.claude/skills/design/scripts/icon/generate.py" --prompt "cloud upload" --batch 4 --output-dir ./icons
```

### Routing Table

| Task | Action |
|------|--------|
| Brand identity, voice | Read `brand/SKILL.md` |
| Design tokens, specs | Read `design-system/SKILL.md` |
| Logo creation | Read `design/SKILL.md` → Logo section |
| CIP deliverables | Read `design/SKILL.md` → CIP section |
| Presentations | Read `design/SKILL.md` → Slides section, then `references/slides-create.md` |
| Banners | Read `banner-design/SKILL.md` or `design/SKILL.md` → Banner section |
| Social photos | Read `design/SKILL.md` → Social Photos section |
| Icons | Read `design/SKILL.md` → Icon section |
| UI styling, color palettes | Use search script with `--domain style` or `--domain color` |
| Typography, font pairings | Use search script with `--domain typography` |
| UX guidelines | Use search script with `--domain ux` |
| Chart recommendations | Use search script with `--domain chart` |

## Data Sources

CSV databases in `src/ui-ux-pro-max/data/`:
- `products.csv` — product type recommendations
- `styles.csv` — 67 UI styles with CSS keywords and AI prompts
- `colors.csv` — 161 color palettes by product type
- `typography.csv` — 57 font pairings with Google Fonts imports
- `charts.csv` — 25 chart types with library recommendations
- `ux.csv` — 99 UX guidelines and anti-patterns
- `landing.csv` — landing page patterns and CTA strategies
- `stacks/` — stack-specific implementation guidelines
