---
name: phase-1-review
description: Review a Phase 1 functional spec for conformance. Determines widget kind, loads kind-specific checks, and produces a PASS/FAIL conformance report.
argument-hint: "[path to functional spec]"
disable-model-invocation: true
allowed-tools:
  - Read
  - Glob
  - Grep
  - Write
  - AskUserQuestion
---

**READ-ONLY — do not modify this file.**

## Input

Spec path (markdown file). Ask user if not provided.

## Kind Detection

Read the spec to determine widget kind (panel / runner / window). Look for `Widget Kind:` in header metadata, or infer from layout:
- **Two-panel** (left panel + main content) = **panel**
- **Three-panel** (status panel + header panel + content panel) = **runner**
- **Window** (standalone feature window) = **window**

## Kind Dispatch

After determining the widget kind, load the corresponding kind-specific checks file from this skill directory:
- panel → `checks-panel.md`
- runner → `checks-runner.md`
- window → `checks-window.md`

## Workflow

1. Read the entire spec.
2. Determine the widget kind. Load the kind-specific checks file.
3. Run **shared checks** (Group B: Header Metadata, Group: No Implementation Detail) plus all **kind-specific checks** in order, recording PASS/FAIL for each.
4. Produce the Conformance Report (template below).
5. Save report to `_local/phase-1-conformance-report.md` in the widget directory (ask user for path if unknown).

---

## Shared Check Group B: Header Metadata

### B1: Widget name in top-level heading
Top-level heading with widget name (e.g., `# Volcano Plot - Functional Specification`).

### B2: Version field present
`**Version:**` present (e.g., `1.0.0`).

### B3: Status field present
`**Status:**` present (e.g., `Draft`, `Approved`).

### B4: Last Updated field present
`**Last Updated:**` present with a date.

### B5: Reference field present
`**Reference:**` present, describing source material. If built from scratch: "Original specification".

### B6: Widget kind identified
Spec must explicitly state the widget kind (typically in 1.1 or 1.3):
- Panel: Tercen -> Widget -> Screen (+ download / write-back)
- Runner: Multi-step workflow manager with Tercen object creation and breakpoints
- Window: Standalone feature window

---

## Shared Check Group: No Implementation Detail

Spec must describe WHAT, never HOW. Scan entire document for violations.

### No code
No Dart code, pseudo-code, or code-like syntax (variable assignments, function calls, class definitions). Exception: ASCII layout diagram.

### No framework references
No Flutter widgets, Provider, GetIt, ChangeNotifier, Consumer, context.watch, setState, or framework-specific terms.

### No pixel values or spacing tokens
No pixel values ("280px"), spacing tokens ("AppSpacing.md"), or CSS-like specs. Exception: domain-specific user-facing sizes ("thumbnail 100x100").

### No colour codes
No hex codes ("#1E40AF"), RGB values, or theme tokens ("AppColors.primary"). Exception: domain-level colour descriptions ("red for upregulated").

### No file paths or import statements
No Dart file paths ("lib/domain/models/"), imports, or package names.

### Mock data describes WHAT not HOW
Section 7.3: no loading mechanisms (`rootBundle`, `loadString()`, `CsvToListConverter`). Only describe what data is needed and where it comes from.

---

## Conformance Report Format

Produce the report in this exact wrapper format. The kind-specific checks file defines which check groups appear in the Results and Failures Detail sections. List every check — do not abbreviate or truncate with "...".

```markdown
# Phase 1 Conformance Report

**Spec:** [spec filename]
**Widget Name:** [name from spec heading]
**Widget Kind:** [panel / runner / window]
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

### B: Header Metadata
- B1: [PASS/FAIL] — Widget name in top-level heading [detail if FAIL]
- B2: [PASS/FAIL] — Version field [detail if FAIL]
- B3: [PASS/FAIL] — Status field [detail if FAIL]
- B4: [PASS/FAIL] — Last Updated field [detail if FAIL]
- B5: [PASS/FAIL] — Reference field [detail if FAIL]
- B6: [PASS/FAIL] — Widget kind identified [detail if FAIL]

[Kind-specific check groups inserted here — see checks-panel.md / checks-runner.md / checks-window.md]

### No Implementation Detail
- [PASS/FAIL] — No code [detail if FAIL]
- [PASS/FAIL] — No framework references [detail if FAIL]
- [PASS/FAIL] — No pixel values or spacing tokens [detail if FAIL]
- [PASS/FAIL] — No colour codes [detail if FAIL]
- [PASS/FAIL] — No file paths or imports [detail if FAIL]
- [PASS/FAIL] — Mock data describes WHAT not HOW [detail if FAIL]

---

## Failures Detail

[For each FAIL, provide:]

### [Check ID]: [Check name]
**Location:** [section number and heading in the spec]
**Expected:** [what should be there]
**Found:** [what was found, or "missing"]
```

---

## Rules for the Reviewer

1. **Report only.** Never edit the spec. Cite section numbers and quote problematic text in failures.
2. **Only check what skills define.** No opinions on domain accuracy, writing quality, or extra requirements.
3. **Judge content, not formatting.** Correct info in non-standard markdown = PASS. Perfect formatting with empty/placeholder content = FAIL.
4. **All checks are binary PASS/FAIL.** No warnings or partial credit.
5. **Domain accuracy is out of scope.** Structural and rule conformance only.
