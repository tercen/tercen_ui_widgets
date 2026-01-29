# Tercen Flutter Development Skills

This directory contains Claude Skills for building Flutter web applications integrated with the Tercen platform.

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

## Required: Tercen Style Specifications

**Before creating any UI**, Claude must read the style specifications in `_local/tercen-style/specifications/`:

| Specification | Purpose |
| ------------- | ------- |
| `Tercen-Layout-Principles.html` | C.R.A.P. design, 8px spacing grid, component sizing |
| `Tercen-Style-Guide.html` | Colors, typography, visual identity |
| `Tercen-Icon-Semantic-Map.html` | FontAwesome + 6 Tercen custom icons |
| `Tercen-Dark-Theme.html` | Dark theme colors, implementation patterns |

See `_local/tercen-style/specifications/README.md` for detailed guidance.

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
│   ├── authentication.md
│   ├── url-parsing.md
│   ├── file-streaming.md
│   ├── concurrency.md
│   ├── error-handling.md
│   ├── tiff-conversion.md
│   ├── app-frame.md       # ← UI: Overall screen structure (read first)
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

## Mandatory Development Workflow

**CRITICAL**: All skills enforce this workflow for non-trivial features:

1. **Enter Plan Mode** (EnterPlanMode tool)
2. **Product Specification** - What are we building? Why? Success criteria?
3. **Technical Specification** - How? Which patterns? What files? What risks?
4. **Implementation Plan** - Step-by-step breakdown, verification strategy
5. **User Approval** (ExitPlanMode tool)
6. **Implementation** - Follow approved plan

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
- **Read `_local/tercen-style/specifications/` FIRST** before creating UI
- Apply Tercen Layout Principles (C.R.A.P., 8px grid, equal gaps)
- Establish design system during **mock phase** (Skill 1)
- Material Design 3 foundation
- Centralized theme files: `app_theme.dart`, `app_colors.dart`, `app_spacing.dart`

## UI Patterns

**Reading order**: app-frame.md → left-panel.md → Functional Spec

### App Frame Pattern

**Overall screen structure** - read this FIRST. See [patterns/app-frame.md](patterns/app-frame.md).

| Topic              | Coverage                                        |
| ------------------ | ----------------------------------------------- |
| Container          | Flex layout, 100vw × 100vh                      |
| Components         | Left panel + main panel composition             |
| App Types          | Simple App, Runner App, Data Step               |
| Top Bar            | When to show, positioning, content              |
| Context Detection  | Embedded vs full screen                         |
| Main Content       | Flow direction, sizing principles               |

### Left Panel Pattern

**Left panel component** - read after app-frame.md. See [patterns/left-panel.md](patterns/left-panel.md).

| Property        | Value                      |
| --------------- | -------------------------- |
| Default width   | 280px                      |
| Collapsed width | 48px                       |
| Header height   | 48px                       |
| Resizable       | Yes (280-400px)            |
| Sections        | NOT collapsible internally |

**Header composition** (required elements):

1. App Icon - click expands when collapsed
2. App Title
3. Theme Toggle - moon (light) / sun (dark)
4. Collapse Chevron

**Collapsed state**:

- Section icons become vertical navigation strip
- Click icon → expands AND scrolls to section
- No duplicate icons (same elements, CSS transform)

**Interactive demo**: `_local/left-panel-testboard.html`

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
