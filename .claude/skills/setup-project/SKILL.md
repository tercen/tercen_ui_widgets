---
name: setup-project
description: Set up a new Tercen Flutter operator project from a skeleton template. Creates the project directory, copies skeleton and skills, and prepares the project structure.
disable-model-invocation: true
argument-hint: "[widget-name]"
---

Set up a new Tercen Flutter operator project called `$ARGUMENTS`.

## Steps

### 1. Determine paths

- **Widget name:** `$ARGUMENTS` (snake_case, e.g., `volcano_explorer`)
- **Operator repo name:** `${ARGUMENTS}_flutter_operator`
- **Target directory:** Ask the user where to create the project, or use the current working directory parent

### 1b. Determine widget kind

Ask the user which widget kind to use:

| Kind | Description |
|------|-------------|
| **panel** | Two-panel layout for visualization and interactive data widgets |
| **runner** | Three-panel layout for workflow manager widgets |
| **window** | Feature window for embedding within the Tercen UI orchestrator |

### 2. Copy skeleton

Copy `skeletons/{kind}/` from the tercen-flutter-skills repo to the target location as `${ARGUMENTS}_flutter_operator/`.

Also copy the `skeleton.yaml` manifest — it stays in the project root so skills can detect the widget kind.

### 3. Update project identity

In the new project:

**pubspec.yaml:**
- `name:` → `${ARGUMENTS}_flutter_operator`
- `description:` → ask the user for a one-line description

**operator.json:**
- `name` → display name (title case of widget name, e.g., "Volcano Explorer")
- `description` → same one-line description
- `urls` → `["https://github.com/tercen/${ARGUMENTS}_flutter_operator"]`
- `isWebApp` → `true`
- `isViewOnly` → `false`
- `entryType` → `"app"`
- `serve` → `"build/web"`

**lib/core/version/version_info.dart:**
- `gitRepo` → `https://github.com/tercen/${ARGUMENTS}_flutter_operator`
- `version` → `'0.1.0'`

### 4. Copy skills and agents

Copy from the tercen-flutter-skills repo into the new project:
- `.claude/skills/` → entire directory
- `.claude/agents/` → entire directory

### 5. Create project directories

Create these directories in the new project:
- `_issues/`
- `_local/`

### 6. Create session log

Create `_issues/session-log.md` with:

```markdown
# Session Log — ${ARGUMENTS}_flutter_operator

Issues, workarounds, and insights captured during development.
Tags: [skill-gap] [sdk-issue] [workaround] [fixed] [pattern]
```

### 7. Prompt for beginning materials

Tell the user:

> Project `${ARGUMENTS}_flutter_operator` is set up as a **{kind}** widget. Before starting Phase 1:
>
> 1. Add any beginning materials to the project — screenshots, data files,
>    existing code, documentation, or anything that describes what the widget should do.
> 2. When ready, run `/run-phase 1` to start the functional spec.

## Do NOT

- Do not start building the widget
- Do not write any application code
- Do not modify skeleton files beyond the identity updates in step 3
- Do not run flutter commands
