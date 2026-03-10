---
name: phase-2-review
description: Review a Phase 2 mock build for conformance against the skeleton template and functional spec. Determines widget kind, runs shared and kind-specific checks, produces a PASS/FAIL report.
argument-hint: "[path to built app] [path to functional spec]"
disable-model-invocation: true
allowed-tools:
  - Read
  - Glob
  - Grep
  - Write
  - AskUserQuestion
---

**READ-ONLY. Do NOT modify this file.**

## Inputs

1. **Built widget directory** -- the Phase 2 output
2. **Functional spec** -- Phase 1 output (markdown)

If missing, ask the user.

---

## Kind Detection

Read `skeleton.yaml` in the widget directory. The `kind` field determines which checks to run:

- `kind: panel` -- panel widget
- `kind: runner` -- runner widget
- `kind: window` -- window widget

If `skeleton.yaml` is not present, fall back to heuristic detection:
- If `lib/presentation/widgets/header_panel.dart` exists -> **runner**
- Otherwise -> **panel**

---

## Kind Dispatch

After determining the kind, load the corresponding checks file from this skill directory:

- **panel** -> `checks-panel.md`
- **runner** -> `checks-runner.md`
- **window** -> `checks-window.md`

Run all **shared check groups** (below) plus all checks from the kind-specific file.

---

## Workflow

1. Read the functional spec.
2. Determine the widget kind (see Kind Detection above).
3. Run shared check groups (C, H, I below).
4. Run kind-specific checks from the dispatched file.
5. Save conformance report to `_local/phase-2-conformance-report.md`.

---

## Shared Check Group C: Placeholder Replacement

Check for skeleton defaults in each file.

### C1: pubspec.yaml

- `name:` must NOT be `skeleton_app` or `skeleton_type3_app`
- `description:` must NOT contain "skeleton"

### C2: operator.json

- `name` must NOT be `"Skeleton App"` or `"Skeleton Runner App"`
- `description` must NOT contain "skeleton"
- `urls` must NOT contain `skeleton_app` or `skeleton_type3_app`
- `isWebApp` must be `true`
- `isViewOnly` must be `false`
- `entryType` must be `"app"`
- `serve` must be `"build/web"`

### C3: version_info.dart

- `gitRepo` must NOT contain `skeleton_app` or `skeleton_type3_app`
- `version` must NOT be `'dev'` (should be `'0.1.0'` or later)

### C4: main.dart class name

- Must NOT contain a class named `SkeletonApp`
- The class name should reflect the widget's name

### C5: home_screen.dart widget identity

- `appTitle:` must NOT be `'Skeleton'` or `'Skeleton App'`
- The App icon (`AppIcon` widget) is hardcoded -- must NOT be modified or removed

---

## Shared Check Group H: Configuration Files

### H1: index.html base href

`web/index.html` must have base href commented out: `<!--<base href="$FLUTTER_BASE_HREF">-->`

### H2: .gitignore preserves build/web

`.gitignore` must contain `!build/web/`.

### H3: analysis_options.yaml exists

---

## Shared Check Group I: Service Locator

### I1: Guard against double registration

Must check `if (serviceLocator.isRegistered<DataService>()) return;` before registering.

### I2: Phase 3 readiness

Must accept optional `useMocks`, `factory`, `taskId` parameters (active or commented stubs).

---

## Conformance Report Format

Produce the report in this exact format. List every check -- do not abbreviate or truncate with "...".

The report must include all shared checks (C, H, I) and all kind-specific checks from the dispatched file. Combine them into a single report.

```markdown
# Phase 2 Conformance Report

**Widget:** [widget name from pubspec.yaml]
**Kind:** [panel / runner / window]
**Spec:** [spec filename]
**Date:** [review date]

## Summary

| Result | Count |
|--------|-------|
| PASS | [n] |
| FAIL | [n] |
| **Total** | [n] |

**Verdict:** [CONFORMING / NON-CONFORMING]

A widget is CONFORMING only if every check is PASS. Any FAIL makes it NON-CONFORMING.

---

## Results

[Kind-specific check groups listed first, then shared groups]

### C: Placeholder Replacement
- C1: [PASS/FAIL] -- pubspec.yaml [detail if FAIL]
- C2: [PASS/FAIL] -- operator.json [detail if FAIL]
- C3: [PASS/FAIL] -- version_info.dart [detail if FAIL]
- C4: [PASS/FAIL] -- main.dart class name [detail if FAIL]
- C5: [PASS/FAIL] -- home_screen.dart widget identity [detail if FAIL]

### H: Configuration
- H1: [PASS/FAIL] -- index.html base href [detail if FAIL]
- H2: [PASS/FAIL] -- .gitignore preserves build/web [detail if FAIL]
- H3: [PASS/FAIL] -- analysis_options.yaml exists [detail if FAIL]

### I: Service Locator
- I1: [PASS/FAIL] -- Guard against double registration [detail if FAIL]
- I2: [PASS/FAIL] -- Phase 3 readiness [detail if FAIL]

---

## Failures Detail

[For each FAIL, provide:]

### [Check ID]: [Check name]
**File:** [file path]
**Line:** [line number if applicable]
**Expected:** [what should be there]
**Found:** [what was found]
**Spec Reference:** [which spec section this relates to, if applicable]
```

---

## Rules

- Report only. Never edit widget files.
- Read the spec first. Cite file paths and line numbers in failures.
- Only check what this skill defines. Do not add opinions beyond the checks.
- DO-NOT-MODIFY: compare literally -- do not accept "equivalent" code.
- Every check is PASS or FAIL. No warnings.
