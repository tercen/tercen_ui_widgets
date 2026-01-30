# Tercen Flutter Development Skills

This directory contains Claude Skills for building Flutter web applications integrated with the Tercen platform.

## Installation

Clone this repository to your project's `.claude/` directory:

```bash
# From your project root
git clone https://github.com/tercen/tercen-flutter-skills.git .claude/skills
```

Alternatively, if given the GitHub URL `https://github.com/tercen/tercen-flutter-skills`, use:

```bash
gh repo clone tercen/tercen-flutter-skills .claude/skills
```

Once installed, proceed to the MANDATORY FIRST STEP below.

---

## MANDATORY FIRST STEP: Clone Style Guide

**At the beginning of EVERY new project**, Claude MUST automatically clone the Tercen style guide:

```bash
# Create _local directory if it doesn't exist
mkdir -p _local

# Clone tercen-style repository (or update if exists)
if [ -d "_local/tercen-style" ]; then
  git -C _local/tercen-style pull
else
  git clone https://github.com/tercen/tercen-style.git _local/tercen-style
fi
```

This is **standard operating procedure** - Claude should do this automatically without the user needing to provide the style guide.

## Required: Tercen UI Design System

**Before creating any UI**, start with the [UI-DESIGN-MAP.md](foundation/UI-DESIGN-MAP.md) - the master navigation for all design documentation.

### Optimized Documentation Structure

```
foundation/           ← Start here
├── UI-DESIGN-MAP.md  ← Master navigation (READ FIRST)
└── design-tokens.md  ← Single source of truth for all values

visual/               ← Color & typography application
├── visual-style-light.md
├── visual-style-dark.md
└── visual-style-icons.md

components/           ← Component specifications
├── component-button.md
├── component-panel.md
├── component-form-controls.md
├── component-grid.md
└── component-table.md

patterns/             ← How components compose
├── app-frame.md      ← Overall structure
└── left-panel.md     ← Left panel pattern
```

**Entry point**: [foundation/UI-DESIGN-MAP.md](foundation/UI-DESIGN-MAP.md)

**Original HTML specifications** (in `_local/tercen-style/specifications/`) remain as visual reference but are not authoritative. Use the optimized markdown files above.

## MANDATORY: Dark Mode Support

**All Tercen apps MUST support both light and dark themes.** This is standard, not optional.

### Implementation Requirements

1. **Theme Provider**: Create `ThemeProvider` with system preference detection
2. **Dual Color Sets**: Use `AppColors` (light) and `AppColorsDark` (dark)
3. **Theme Toggle**: Add sun/moon toggle to left panel header
4. **Persistence**: Save user preference to SharedPreferences
5. **System Default**: Follow OS preference when no user override

### Theme Control

| Scenario | Action |
| -------- | ------ |
| First visit | Follow system preference (`prefers-color-scheme`) |
| User toggles | Override system, save to localStorage |
| User clears | Return to system preference |

### Color Distinction

| Theme | Primary Accent | Rationale |
| ----- | -------------- | --------- |
| Light | Blue (#1E40AF) | Tercen brand blue |
| Dark | Violet (#6D28D9) with white text | Tercen violet, high contrast |
| Links (dark) | Teal (#2DD4BF) | Distinct from action buttons |

See `Tercen-Dark-Theme.html` for complete color tokens and Flutter implementation patterns.

## Directory Structure

This skills system uses a **modular architecture** for maintainability and cross-referencing:

```
.claude/skills/
├── README.md              # This file - overview and index
├── skills/                # Main skill documents (4 skills)
│   ├── 0-flutter-foundation.md
│   ├── 1-tercen-mock.md
│   ├── 2-tercen-real.md
│   └── 3-customer-pamgene.md
├── patterns/              # Reusable code patterns
│   ├── functional-spec-discovery.md  # ← Planning: Read in Phase 2
│   ├── authentication.md
│   ├── url-parsing.md
│   ├── file-streaming.md
│   ├── concurrency.md
│   ├── error-handling.md
│   ├── tiff-conversion.md
│   ├── app-frame.md       # ← UI: Overall screen structure
│   └── left-panel.md      # ← UI: Left panel component
└── issues/                # Operational gotchas (1-11)
    ├── 1-wasm-build.md
    ├── 2-build-web-commit.md
    ├── 3-cors-errors.md
    ├── 4-index-html-line17.md
    ├── 5-tercen-file-structure.md
    ├── 6-dev-files-organization.md
    ├── 7-hot-reload-broken.md
    ├── 8-mandatory-workflow.md
    ├── 9-ui-design-standards.md
    ├── 10-metadata-data-resolution.md
    └── 11-schema-filtering.md
```

## Skills Overview

These skills provide reusable patterns for Tercen Flutter development.

### Skill Hierarchy

```
Skill 0: Flutter Foundation (Base)
    ↓
Skill 1: Mock Implementation
    ↓
Skill 2: Tercen Real Implementation
    ↓
Skill 3: Customer PamGene (Domain-Specific)
```

Each skill extends the previous one, building on established patterns.

## Available Skills

### Skill 0: [flutter-foundation.md](flutter-foundation.md)
**Generic Flutter patterns - Foundation for all projects**

- GetIt dependency injection
- Provider state management
- Clean architecture (Presentation → Domain → Implementation)
- Testing strategy (unit, widget, provider, integration)
- Mock vs Real implementation switching
- Directory structure conventions

**Use when**: Starting any new Flutter project

---

### Skill 1: [tercen-mock-implementation.md](tercen-mock-implementation.md)
**Build UI with mock data first**

- Mock-first development workflow
- Asset-based mock data patterns
- UI Design Standards (Material Design 3)
- Design system creation (theme, colors, spacing)
- Quick iteration without backend dependency
- **CRITICAL**: Hot reload doesn't work - always stop and restart

**Use when**: Creating UI/UX before Tercen API integration

---

### Skill 2: [tercen-real-implementation.md](tercen-real-implementation.md)
**Integrate with Tercen platform API**

- **Auto-fetches** from `sci_tercen_client`, `sci_http_client`, `sci_base`, `sci_tercen_model`
- Authentication patterns (web app flow)
- ServiceFactory usage
- URL path parsing (standalone vs workflow modes)
- File streaming and download
- Error handling with fallback to mocks
- Concurrency management
- **9 Critical Operational Issues** documented (WASM build, CORS, index.html, etc.)

**Use when**: Connecting mock implementation to real Tercen API

---

### Skill 3: [customer-pamgene.md](customer-pamgene.md)
**PamGene-specific patterns and conventions**

- PamGene filename parsing (`{barcode}_W{well}_F{field}...`)
- TIFF conversion utilities (16-bit → 8-bit PNG)
- Grid layout patterns (270px × 200px cells)
- Well/Field/Array mapping
- Filter defaults (latest cycle, longest exposure)
- Domain-specific UI patterns

**Use when**: Building PamGene-specific features or microscopy image tools

---

## Operating Modes

These skills support two distinct modes. **Claude MUST determine the mode** before proceeding.

### How to Determine Mode

| Indicator | Mode |
| --------- | ---- |
| User provides functional spec document | **Test Mode** |
| User says "test", "validate", "regression" | **Test Mode** |
| User describes what they want to build | **Development Mode** |
| User asks to create/design an app | **Development Mode** |
| **Unclear from prompt** | **Ask the user** |

**If unclear**, Claude should ask:
> "Are we in **Development Mode** (creating a new app with planning) or **Test Mode** (validating skills with a pre-existing spec)?"

---

### Mode A: Development Mode (Full Workflow)

**Use when**: Building a real application where requirements need discovery and the functional specification needs to be developed collaboratively.

**Characteristics**:

- User describes what they want (not a complete spec)
- Planning phase required
- User provides assets/data during development
- Iterative refinement expected

### Mode B: Test Mode (Skills Validation)

**Use when**: Running regression tests to validate that skills produce consistent, correct output given the same inputs.

**Characteristics**:

- Pre-generated functional specification provided
- Mock data/assets already available
- No planning phase needed
- Deterministic execution expected
- Purpose: Verify skills haven't been broken by changes

**Test Mode workflow**:

1. Complete Phase 1 Setup (clone repos, read specs)
2. **Skip Phase 2** (planning already done)
3. Read the provided functional specification
4. Execute Phase 3 (implementation)
5. Verify output matches expected results

---

## Development Mode Workflow

**CRITICAL**: This workflow applies to Development Mode only.

### Phase 1: Setup (Before ANY Planning)

When given the GitHub URL for this skills repo, Claude MUST:

1. **Clone this skills repo** into `.claude/skills/`

   ```bash
   gh repo clone tercen/tercen-flutter-skills .claude/skills
   ```

2. **Clone the style guide** (see MANDATORY FIRST STEP above)

   ```bash
   mkdir -p _local
   git clone https://github.com/tercen/tercen-style.git _local/tercen-style
   ```

3. **Read the UI design system** (required before any UI planning):
   - [ ] `foundation/UI-DESIGN-MAP.md` (master navigation - read first)
   - [ ] `foundation/design-tokens.md` (all dimension, color, typography values)
   - [ ] `visual/visual-style-light.md` (color application for light theme)
   - [ ] `patterns/app-frame.md` and `patterns/left-panel.md` (structure patterns)

4. **Identify skill level** based on project requirements:
   - Skill 0: Generic Flutter (always read first)
   - Skill 1: Mock implementation (UI development)
   - Skill 2: Tercen API integration
   - Skill 3: PamGene domain (if applicable)

5. **Read relevant skill document(s)** in `.claude/skills/skills/`

### Phase 2: Planning (Plan Mode)

Only AFTER completing Phase 1:

1. **Enter Plan Mode** (EnterPlanMode tool)
2. **Functional Specification Discovery** - Use [patterns/functional-spec-discovery.md](patterns/functional-spec-discovery.md) to gather requirements through discovery questions
3. **Draft Functional Specification** - Write spec document with all 8 sections
4. **Technical Specification** - How? Which patterns? What files? What risks?
5. **Implementation Plan** - Step-by-step breakdown, verification strategy
6. **User Approval** (ExitPlanMode tool)

### Phase 3: Implementation

1. **Implementation** - Follow approved plan, applying skill patterns

**Why this matters**: Real projects have experienced authentication issues, URL parsing problems, and deployment confusion that planning would have prevented.

## How to Use These Skills

### Quick Start

1. **Clone the style guide FIRST** (automatic - see "MANDATORY FIRST STEP" above)
2. Review the skill you need
3. The skill will auto-fetch necessary GitHub repos (Skills 1-3)
4. Follow the documented patterns
5. Apply the checklists
6. Avoid the documented gotchas

### Auto-Fetch Mechanism

Skills automatically clone reference repositories to `/tmp/tercen-refs/`:

- **Skill 2**: All 4 Tercen API repos (sci_tercen_client, sci_http_client, sci_base, sci_tercen_model)

### Key Repositories Referenced

1. **sci_tercen_client** (v1.7.0) - Official Tercen Dart client
2. **sci_http_client** (v1.0.4) - HTTP client with CORS handling
3. **sci_base** (v1.2.1) - Core service abstractions
4. **sci_tercen_model** (v1.0.0) - 214+ Tercen data models

## Critical Gotchas (Issue #1-9)

### Issue #1: WASM Build Workflow
- Build with `flutter build web --wasm`
- Commit `build/web/` directory
- Each Tercen test requires: build → commit → push → wait

### Issue #2: build/web/ Must Be Committed
```gitignore
/build/          # Ignore all
!/build/web/     # EXCEPT this - Tercen serves from here
```

### Issue #3: Always Use sci_tercen_client
- Never manual HTTP calls - CORS will block
- Use `createServiceFactoryForWebApp()` for auth

### Issue #4: index.html Line 17
```html
<!--<base href="$FLUTTER_BASE_HREF"> -->
```
**MUST be commented** or routing breaks in Tercen.

### Issue #5: Required Files
- `operator.json` with `"serve": "build/web"`
- `README.md` with Tercen conventions
- `build/web/` directory committed

### Issue #6: Dev Files Organization
- Git ignore: `chat_review/`, `.claude/`, `tmp/`, `tmpclaude-*`
- Commit: `README.md`, `docs/` (optional)

### Issue #7: Hot Reload Does NOT Work
**Always stop and restart** - hot reload is unreliable for Flutter web.

### Issue #8: Mandatory Workflow
**Plan Mode required** for all non-trivial features. No skipping specs.

### Issue #9: UI Design Standards
- **Read [foundation/UI-DESIGN-MAP.md](foundation/UI-DESIGN-MAP.md) FIRST** before creating UI
- Follow [design-tokens.md](foundation/design-tokens.md) for all values (8px grid, spacing scale)
- Apply C.R.A.P. principles: Contrast, Repetition, Alignment, Proximity
- Equal gaps in grids (4px both directions)
- Panel header: accent background + white text
- Establish design system during **mock phase** (Skill 1)
- Material Design 3 foundation
- Centralized theme files: `app_theme.dart`, `app_colors.dart`, `app_spacing.dart`

## UI Patterns

**Entry point**: [foundation/UI-DESIGN-MAP.md](foundation/UI-DESIGN-MAP.md) - Master navigation for all UI documentation

**Reading order**: UI-DESIGN-MAP → design-tokens → visual-style-light → app-frame → left-panel

### Design System Hierarchy

```
1. FOUNDATION (read first)
   ├── UI-DESIGN-MAP.md ← Master navigation, decision tree
   └── design-tokens.md ← Single source of truth (spacing, colors, dimensions)

2. VISUAL STYLE (colors, typography applied)
   ├── visual-style-light.md
   ├── visual-style-dark.md
   └── visual-style-icons.md

3. COMPONENTS (what exists, how it works)
   ├── component-button.md
   ├── component-panel.md
   ├── component-form-controls.md
   ├── component-grid.md
   └── component-table.md

4. PATTERNS (how components compose)
   ├── app-frame.md     ← Overall screen structure
   └── left-panel.md    ← Left panel composition
```

### Key Specifications

| Topic | File | Key Info |
|-------|------|----------|
| **All values** | [design-tokens.md](foundation/design-tokens.md) | Spacing (4,8,16,24,32,48), dimensions, colors |
| **Screen structure** | [app-frame.md](patterns/app-frame.md) | Container, panels, 3 app types, context detection |
| **Left panel** | [left-panel.md](patterns/left-panel.md) | 280px default, 48px collapsed, header composition |
| **Panel component** | [component-panel.md](components/component-panel.md) | Complete panel behavior, collapse, resize |
| **Light theme** | [visual-style-light.md](visual/visual-style-light.md) | Color application, button styles, form controls |
| **Dark theme** | [visual-style-dark.md](visual/visual-style-dark.md) | Violet accent, dark backgrounds, contrast |
| **Icons** | [visual-style-icons.md](visual/visual-style-icons.md) | FontAwesome selection, semantic colors |

**Benefits of optimized structure**:
- Zero redundancy (single source of truth)
- Clear separation of concerns (layout ≠ style ≠ behavior)
- 62% token reduction vs HTML format
- Reference-based (no duplication)
- Discoverable hierarchy with decision tree

## Implementation Status

- [x] Plan completed and approved
- [ ] Skill 0: flutter-foundation.md (NEXT)
- [ ] Skill 1: tercen-mock-implementation.md
- [ ] Skill 2: tercen-real-implementation.md
- [ ] Skill 3: customer-pamgene.md

**Full plan reference**: `C:\Users\Work\.claude\plans\iterative-tumbling-stallman.md`

## Benefits

- No manual repository lookup required
- Patterns always current (auto-fetched from latest)
- Consistent implementation across all Tercen Flutter projects
- Institutional knowledge preserved and accessible
- New developers onboard faster
- **Authentication and deployment issues won't repeat**
- **All operational gotchas documented and enforced**
