---
name: phase-2-mock
description: Build an HTML mock from a Phase 1 functional spec. Three steps — wireframe, styled rendering, gap evaluation. Produces HTML files in widgets/{name}/_mock/ using Material CSS + Tercen tokens.
argument-hint: "[path to functional spec]"
disable-model-invocation: true
---

**READ-ONLY. Do NOT modify. Log gaps to `_issues/session-log.md` and continue.**

## Inputs

1. **Functional spec** — at `widgets/{name}/{name}-spec.md`
2. **Tercen tokens CSS** — at `../tercen-style/dist/tercen-tokens.css`
3. **Primitive metadata** — at `../tercen-style/theme-export.json` (primitives array)
4. **Approval flags** — at `../tercen-style/tokens.meta.json`

## Output Directory

`widgets/{name}/_mock/`

---

## Step 1 — Wireframe (`wireframe.html`)

Build an HTML/CSS layout skeleton with minimal styling (grey boxes, placeholder text).

- Shows feature placement, content areas, control types from the spec
- Each element annotated with its function (`data-function` attribute or visible label)
- Use semantic HTML: `<header>`, `<main>`, `<aside>`, `<section>`, `<article>`
- Include a note at the top: "Wireframe — layout and features only, no styling"
- Goal: agree feature set and spatial layout with user

---

## Step 2 — Styled Rendering (`styled.html`)

Copy wireframe structure, then apply the Tercen design system.

### Embedding Tercen tokens

Read `../tercen-style/dist/tercen-tokens.css` and embed the full contents in a `<style>` tag in the HTML `<head>`. Do NOT use a `<link>` tag (the relative path `../../../tercen-style/dist/tercen-tokens.css` will not resolve cross-repo).

### Applying the theme

- Font family from CSS variable `--tc-font-family` (or equivalent token)
- Colours from approved tokens only (check `../tercen-style/tokens.meta.json` — only use colours where `approved: true`)
- Spacing from token CSS variables
- Border radius from token CSS variables

### Controls

- Reference `../tercen-style/tokens.meta.json` components section for control specs
- Buttons: correct padding, border-radius, colours per variant (primary, secondary, ghost)
- Inputs: outline borders, correct focus states
- All controls rendered to match the style guide

### Theme toggle

Include a theme toggle button (light/dark) using the CSS `[data-theme]` selectors defined in the tokens CSS.

### Goal

Visual fidelity check — "does this look like Tercen?"

---

## Step 3 — Gap Evaluation (`gap-report.md`)

For each UI element in the styled mock, check against primitives in `../tercen-style/theme-export.json` (primitives array).

### Five gap categories

| Category | Description |
|----------|-------------|
| **Primitive gap** | Needs X, doesn't exist in SDUI |
| **Variant gap** | Needs X variant of Y, Y exists but lacks this variant |
| **Prop gap** | Needs prop Z on primitive Y |
| **Composition question** | Can achieve with existing primitives via pattern P? |
| **Style gap** | Needs token not in approved set |

### Output

Markdown file with a categorised table. Each row: element name, gap category, description, proposed resolution.

If no gaps found, state: "All elements map to existing SDUI primitives."

---

## Mock Data

Use static JSON fixture files in `widgets/{name}/_fixtures/`.

- Data must be realistic (real-looking names, timestamps, IDs) but not from live API
- All four states must be represented:
  - **loading** — in-progress indicator
  - **empty** — no data available
  - **active** — populated with realistic data
  - **error** — error condition with message

---

## Rules

- Only use approved colour tokens (check `tokens.meta.json` colors where `approved: true`)
- Only use approved text styles from `theme-export.json`
- FontAwesome 6 Solid for icons — CDN link: `https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.5.1/css/all.min.css`
- No real API connections, no EventBus wiring
- The HTML is a design artifact, not code to port

---

## Checklist

Before completing Phase 2:

- [ ] wireframe.html created and reviewed with user
- [ ] styled.html created with Tercen theme applied
- [ ] All controls match style guide specs
- [ ] Mock data fixtures created with realistic data
- [ ] All 4 states represented (loading, empty, active, error)
- [ ] gap-report.md produced
- [ ] Only approved colour tokens used
- [ ] FontAwesome 6 Solid icons only
