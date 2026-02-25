---
name: setup-project
description: Set up a new Tercen Flutter operator project from the skeleton template. Creates the project directory, copies skeleton and skills, and prepares the project structure.
disable-model-invocation: true
argument-hint: "[app-name]"
---

Set up a new Tercen Flutter operator project called `$ARGUMENTS`.

## Steps

### 1. Determine paths

- **App name:** `$ARGUMENTS` (snake_case, e.g., `volcano_explorer`)
- **Operator repo name:** `${ARGUMENTS}_flutter_operator`
- **Target directory:** Ask the user where to create the project, or use the current working directory parent

### 1b. Determine app type

Ask the user: **"Is this a Type 1/2 app (visualization/interactive) or a Type 3 app (workflow manager)?"**

- **Type 1/2:** Standard visualization or data write-back app
- **Type 3:** Multi-step workflow manager with run history and status tracking

### 2. Copy skeleton

- **Type 1/2:** Copy `skeleton/` from the tercen-flutter-skills repo
- **Type 3:** Copy `skeleton-type3/` from the tercen-flutter-skills repo

Copy to the target location as `${ARGUMENTS}_flutter_operator/`.

### 3. Update project identity

In the new project:

**pubspec.yaml:**
- `name:` → `${ARGUMENTS}_flutter_operator`
- `description:` → ask the user for a one-line description

**operator.json:**
- `name` → display name (title case of app name, e.g., "Volcano Explorer")
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

> Project `${ARGUMENTS}_flutter_operator` is set up. Before starting Phase 1:
>
> 1. Add any beginning materials to the project — screenshots, data files,
>    existing code, documentation, or anything that describes what the app should do.
> 2. When ready, run `/run-phase 1` to start the functional spec.

## Do NOT

- Do not start building the app
- Do not write any application code
- Do not modify skeleton files beyond the identity updates in step 3
- Do not run flutter commands
