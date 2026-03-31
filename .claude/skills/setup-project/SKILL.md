---
name: setup-project
description: Set up a new Tercen window/header widget project. Creates the project directory structure and prepares for Phase 1 spec writing.
disable-model-invocation: true
argument-hint: "[widget-name]"
---

Set up a new Tercen window/header widget project called `$ARGUMENTS`.

## Steps

### 1. Determine paths

- **Widget name:** `$ARGUMENTS` (snake_case, e.g., `volcano_explorer`)
- **Target directory:** `widgets/${ARGUMENTS}/`

### 2. Validate name

Ensure the widget name is snake_case and does not conflict with an existing directory under `widgets/`.

### 3. Ask for description

Ask the user for a one-line description of what the widget does.

### 4. Create project directories

Create these directories:
- `widgets/${ARGUMENTS}/`
- `widgets/${ARGUMENTS}/_mock/`
- `widgets/${ARGUMENTS}/_fixtures/`
- `_issues/` (if it does not already exist)
- `_local/` (if it does not already exist)

### 5. Create spec placeholder

Create `widgets/${ARGUMENTS}/${ARGUMENTS}-spec.md` with:

```markdown
# ${ARGUMENTS} — Functional Spec

**Kind:** window
**Status:** draft

## 1. Overview

[To be filled in during Phase 1]
```

### 6. Create session log (if needed)

If `_issues/session-log.md` does not already exist, create it with:

```markdown
# Session Log — tercen_ui_widgets

Issues, workarounds, and insights captured during development.
Tags: [skill-gap] [sdk-issue] [workaround] [fixed] [pattern]
```

### 7. Prompt for beginning materials

Tell the user:

> Project `${ARGUMENTS}` is set up as a **window** widget. Before starting Phase 1:
>
> 1. Add any beginning materials to `widgets/${ARGUMENTS}/` — screenshots, data files,
>    existing code, documentation, or anything that describes what the widget should do.
> 2. When ready, run `/run-phase 1` to start the functional spec.

## Do NOT

- Do not start building the widget
- Do not write any application code
- Do not run flutter commands
