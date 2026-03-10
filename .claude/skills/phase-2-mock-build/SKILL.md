---
name: phase-2-mock-build
description: Build a mock Flutter widget from a Phase 1 functional spec. Copies the appropriate skeleton, wires controls to a mock data service, and produces a runnable widget with no Tercen dependency.
argument-hint: "[path to functional spec]"
disable-model-invocation: true
---

**READ-ONLY. Do NOT modify. Log gaps to `_issues/session-log.md` and continue.**

Determine the widget kind from the project's `skeleton.yaml` or the spec header. Load the kind-specific build guide.

| Kind | Build guide |
|------|-------------|
| panel | `build-panel.md` |
| runner | `build-runner.md` |
| window | `build-window.md` |

Reference: `_references/global-rules.md`

## Inputs

1. **Functional spec** — Phase 1 output (markdown)
2. **Skeleton** — `skeletons/{kind}/` from tercen-flutter-skills
3. **Target directory** — new project location
4. **Mock data** — files described in spec Section 7.3

---

## Step 1: Copy and Rename

Copy the entire `skeletons/{kind}/` directory to the target project location, then update these files:

### pubspec.yaml
- `name:` — new widget name in snake_case (e.g., `volcano_flutter_operator`)
- `description:` — one-line description from spec Section 1.1

### operator.json
- `name` — display name from spec (e.g., "Volcano Plot")
- `description` — one-line description
- `urls` — GitHub repository URL

### version_info.dart (`lib/core/version/version_info.dart`)
- `gitRepo` — GitHub repository URL
- `version` — set to `'0.1.0'`
- `commitHash` — leave empty (populated at build time)

### main.dart (`lib/main.dart`)
- Rename Skeleton class -> widget name class
- Update `title:` in `MaterialApp`

### home_screen.dart (`lib/presentation/screens/home_screen.dart`)
- Update `appTitle:` — display name shown in panel header
- The App icon is hardcoded in `LeftPanelHeader` — do NOT modify it

After Step 1, follow the kind-specific build guide for Steps 2 onward.
