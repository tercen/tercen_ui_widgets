---
name: phase-1-functional-spec
description: Write a functional specification for a new Tercen Flutter web widget. Use when starting a new widget, converting an existing one, or when the user asks for a spec, requirements, or functional design. Produces a complete spec document with no code. Supports panel, runner, and window widget kinds.
argument-hint: "[widget name or description]"
disable-model-invocation: true
---

**READ-ONLY. Do NOT modify. Log gaps to `_issues/session-log.md` and continue.**

Produce a functional spec document. Do NOT write any code.

For shared patterns: `_references/global-rules.md`.

---

## Determine the Widget Kind

1. Check whether the target project contains a `skeleton.yaml` file. If it does, read the `kind` field to determine the widget kind.
2. If no `skeleton.yaml` exists, ask the user which widget kind this is.

### Kind Dispatch

| Kind | Template File |
|------|--------------|
| panel | `template-panel.md` |
| runner | `template-runner.md` |
| window | `template-window.md` |

Load the matching template file from this skill directory and follow its constraints, spec template, discovery process, and checklist.

---

## Output Rules

- The spec describes WHAT the widget does, never HOW it is implemented.
- No Dart code, no pseudo-code, no implementation approach.
- No pixel values, spacing tokens, or colour codes (except domain-specific colours like chart series colours).
- No references to Flutter widgets, Provider, GetIt, or any framework.
- Mock data requirements describe WHAT data is needed and WHERE it comes from, not how to load it.

---

## Question Efficiency

- Do NOT dump all questions at once. Ask 3-4 per round.
- Skip questions already answered by provided material (existing code, screenshots, etc.).
- When reviewing existing code/UI, proactively identify constraint violations and propose fixes.
- Consolidate related questions.
