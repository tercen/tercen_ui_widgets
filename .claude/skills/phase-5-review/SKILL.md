---
name: phase-5-review
description: Phase 5 — Review a catalog.json integration for conformance against SDUI rules, data connections, and semantic token usage. Runs as a read-only reviewer agent that produces a PASS/FAIL conformance report. Use after Phase 4 catalog authoring is complete. Assumes Phase 2 conformance has already been verified.
argument-hint: "[path to catalog.json] [path to functional spec]"
disable-model-invocation: true
allowed-tools:
  - Read
  - Glob
  - Grep
  - Write
  - AskUserQuestion
---

**This file is READ-ONLY during reviews. Do NOT modify it.**

This repo is for **window/header widgets only**. Always dispatch to `checks-catalog.md`.

Load and follow `checks-catalog.md` in this same skill directory. It has its own complete workflow, check groups, and report format designed for catalog.json integrations.

---

## Inputs

- **catalog.json entry** — the Phase 4 output
- **Functional spec** — the Phase 1 output document (markdown file)
- **HTML mock** — the Phase 2 output (`_mock/` directory)

If missing, ask the user.

---

## Workflow

1. Load `checks-catalog.md` from this skill directory
2. Follow its workflow, check groups, and report format exactly
3. Save the conformance report to `_local/review-5.md`

---

## Rules

1. **Read the spec first.** Understand the widget before starting checks.
2. **Report only.** Never edit application files or catalog.json.
3. **Only check what checks-catalog.md defines.** Do not add opinions beyond what is specified.
4. **Cite file paths in failures.** Phase 2 is assumed passing — do not re-check Phase 2 requirements.
