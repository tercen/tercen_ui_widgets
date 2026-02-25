---
name: phase-1-review
description: Review a Phase 1 functional spec for conformance to all structural and content rules. Runs as a read-only reviewer agent that produces a PASS/FAIL conformance report. Use after a functional spec is written and before starting Phase 2.
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

## Workflow

1. Read the entire spec. Run all checks A–H in order, recording PASS/FAIL for each.
2. Produce the Conformance Report (template below). Report only — never edit the spec.
3. Save report to `_local/phase-1-conformance-report.md` in the app directory (ask user for path if unknown).

---

## Check Group A: Document Structure

All 8 sections required with meaningful content (not empty or "TBD").

### A1: Section 1 — Overview
Subsections: **1.1 Purpose** (paragraph on what app does), **1.2 Users**, **1.3 Scope** (explicit "In Scope" / "Out of Scope" lists).

### A2: Section 2 — Domain Context
Subsections: **2.1 Background**, **2.2 Data Source** (table with Column/Description/Example; must describe Tercen projections like `.y`, `.ci`, `.ri`, `.x`, labels, colours and data characteristics: ranges, counts, sparsity), **2.3 Typical Workflow** (numbered steps).

### A3: Section 3 — Functional Requirements
Requirements table with columns: ID, Requirement, Priority (Must / Should / Could).

### A4: Section 4 — User Interface Components
Subsections: **4.1 App Structure** (ASCII layout — see Group C), **4.2 Left Panel Sections** (controls — see Group D), **4.3 Main Panel**.

### A5: Section 5 — Non-Functional Requirements
Table with ID and Requirement columns. At least one entry.

### A6: Section 6 — Feature Summary
Categorized feature tables: **Must Have**, **Should Have**, **Could Have**. Each with Feature and Status columns.

### A7: Section 7 — Assumptions
Subsections: **7.1 Data Assumptions**, **7.2 Environment Assumptions**, **7.3 Mock Data** (available data, characteristics, mapping to Section 2.2).

### A8: Section 8 — Glossary
Table with Term and Definition columns. Section must exist even if no terms apply (add a note).

---

## Check Group B: Header Metadata

### B1: App name present
Top-level heading with app name (e.g., `# Volcano Plot - Functional Specification`).

### B2: Version field
`**Version:**` present (e.g., `1.0.0`).

### B3: Status field
`**Status:**` present (e.g., `Draft`, `Approved`).

### B4: Last Updated field
`**Last Updated:**` present with a date.

### B5: Reference field
`**Reference:**` present, describing source material. If built from scratch: "Original specification".

### B6: App type identified
Spec must explicitly state the app type (typically in 1.1 or 1.3):
- Type 1 (Visualization): Tercen -> App -> Screen (+ download)
- Type 2 (Interactive): Type 1 + writes data back to Tercen
- Type 3 (Workflow Manager): Multi-step with Tercen object creation and breakpoints

---

## Check Group C: Layout Diagram

### C1: ASCII diagram present
Section 4.1 must contain an ASCII layout diagram showing left panel and main content area.

### C2: Diagram shows left panel
Diagram must show a left panel region with section names.

### C3: Diagram shows main content
Diagram must show a main content region describing what it displays.

### C4: Diagram matches sections
Every section name in the diagram must match a section in 4.2 and vice versa. No mismatches in either direction.

---

## Check Group D: Left Panel Sections

### D1: Every section has icon and label
Each section in 4.2 must specify an icon (by name/purpose) and an UPPERCASE label (e.g., "FILTERS", "SETTINGS").

### D2: INFO section present
INFO section must exist and be the last section listed.

### D3: INFO section has GitHub link
INFO section must include a GitHub repository link.

### D4: Controls have required attributes
Every control in 4.2 must specify: **name**, **type** (from E1 list), **default**, **range/notes**.

### D5: ALL controls in left panel
All interactive controls must be in Section 4.2. Section 4.3 (Main Panel) may only have read-only interactions (hover tooltips, click-to-select/highlight, zoom/pan, drag-to-select, context menus for export). No sliders, dropdowns, text inputs, state-changing buttons, toggles, checkboxes, or radio buttons in main panel.

---

## Check Group E: Control Types

### E1: Only allowed control types used

Allowed types: dropdown, slider, range slider, toggle (switch), number input, button, searchable input, text input, checkbox, radio, segmented button.

Any other type (e.g., "color picker", "date picker", "tree view", "multi-select list") is a FAIL. Record each control:

| Section | Control Name | Type | Allowed | PASS/FAIL |
|---------|-------------|------|---------|-----------|

---

## Check Group F: No Implementation Detail

Spec must describe WHAT, never HOW. Scan entire document for violations.

### F1: No code
No Dart code, pseudo-code, or code-like syntax (variable assignments, function calls, class definitions). Exception: ASCII layout diagram.

### F2: No framework references
No Flutter widgets, Provider, GetIt, ChangeNotifier, Consumer, context.watch, setState, or framework-specific terms.

### F3: No pixel values or spacing tokens
No pixel values ("280px"), spacing tokens ("AppSpacing.md"), or CSS-like specs. Exception: domain-specific user-facing sizes ("thumbnail 100x100").

### F4: No colour codes
No hex codes ("#1E40AF"), RGB values, or theme tokens ("AppColors.primary"). Exception: domain-level colour descriptions ("red for upregulated").

### F5: No file paths or import statements
No Dart file paths ("lib/domain/models/"), imports, or package names.

### F6: Mock data describes WHAT not HOW
Section 7.3: no loading mechanisms (`rootBundle`, `loadString()`, `CsvToListConverter`). Only describe what data is needed and where it comes from.

---

## Check Group G: Feature Consistency

### G1: Requirements trace to features
Every "Must" requirement in Section 3 must appear in the "Must Have" table in Section 6. Cross-reference:

| Requirement ID | Requirement | In Must Have Table | PASS/FAIL |
|---|---|---|---|

### G2: Controls trace to requirements
Every control in 4.2 should relate to at least one requirement in Section 3. Unrelated controls indicate a spec gap.

### G3: Main panel matches requirements
Section 4.3 must cover display/visualization requirements from Section 3. Any "display X" requirement must be reflected.

### G4: Data source supports requirements
Section 2.2 must provide the columns/values needed for all requirements. Missing data = FAIL.

---

## Check Group H: Mock Data Completeness

### H1: Mock data described
Section 7.3 must describe available mock/example data. Not empty or "TBD".

### H2: Data characteristics specified
Section 7.3 must include: approximate row count, value ranges, data types, sparsity.

### H3: Mock data maps to data source
Section 7.3 must map mock data to Section 2.2 clearly enough that a Phase 2 builder knows exactly what CSV columns/file structure to create.

---

## Conformance Report Format

Produce the report in this exact format. List every check — do not abbreviate or truncate with "...".

```markdown
# Phase 1 Conformance Report

**Spec:** [spec filename]
**App Name:** [app name from spec heading]
**App Type:** [1 / 2 / 3]
**Date:** [review date]

## Summary

| Result | Count |
|--------|-------|
| PASS | [n] |
| FAIL | [n] |
| **Total** | [n] |

**Verdict:** [CONFORMING / NON-CONFORMING]

An app is CONFORMING only if every check is PASS. Any FAIL makes it NON-CONFORMING.

---

## Results

### A: Document Structure
- A1: [PASS/FAIL] — Section 1: Overview [detail if FAIL]
- A2: [PASS/FAIL] — Section 2: Domain Context [detail if FAIL]
- A3: [PASS/FAIL] — Section 3: Functional Requirements [detail if FAIL]
- A4: [PASS/FAIL] — Section 4: User Interface Components [detail if FAIL]
- A5: [PASS/FAIL] — Section 5: Non-Functional Requirements [detail if FAIL]
- A6: [PASS/FAIL] — Section 6: Feature Summary [detail if FAIL]
- A7: [PASS/FAIL] — Section 7: Assumptions [detail if FAIL]
- A8: [PASS/FAIL] — Section 8: Glossary [detail if FAIL]

### B: Header Metadata
- B1: [PASS/FAIL] — App name present [detail if FAIL]
- B2: [PASS/FAIL] — Version field [detail if FAIL]
- B3: [PASS/FAIL] — Status field [detail if FAIL]
- B4: [PASS/FAIL] — Last Updated field [detail if FAIL]
- B5: [PASS/FAIL] — Reference field [detail if FAIL]
- B6: [PASS/FAIL] — App type identified [detail if FAIL]

### C: Layout Diagram
- C1: [PASS/FAIL] — ASCII diagram present [detail if FAIL]
- C2: [PASS/FAIL] — Diagram shows left panel [detail if FAIL]
- C3: [PASS/FAIL] — Diagram shows main content [detail if FAIL]
- C4: [PASS/FAIL] — Diagram matches sections [detail if FAIL]

### D: Left Panel Sections
- D1: [PASS/FAIL] — Every section has icon and UPPERCASE label [detail if FAIL]
- D2: [PASS/FAIL] — INFO section present and last [detail if FAIL]
- D3: [PASS/FAIL] — INFO has GitHub link [detail if FAIL]
- D4: [PASS/FAIL] — Controls have required attributes [detail if FAIL]
- D5: [PASS/FAIL] — All controls in left panel [detail if FAIL]

### E: Control Types
- E1: [PASS/FAIL] — Only allowed control types [detail if FAIL]
  [include the control type table]

### F: No Implementation Detail
- F1: [PASS/FAIL] — No code [detail if FAIL]
- F2: [PASS/FAIL] — No framework references [detail if FAIL]
- F3: [PASS/FAIL] — No pixel values or spacing tokens [detail if FAIL]
- F4: [PASS/FAIL] — No colour codes [detail if FAIL]
- F5: [PASS/FAIL] — No file paths or imports [detail if FAIL]
- F6: [PASS/FAIL] — Mock data describes WHAT not HOW [detail if FAIL]

### G: Feature Consistency
- G1: [PASS/FAIL] — Requirements trace to features [detail if FAIL]
  [include the cross-reference table]
- G2: [PASS/FAIL] — Controls trace to requirements [detail if FAIL]
- G3: [PASS/FAIL] — Main panel matches requirements [detail if FAIL]
- G4: [PASS/FAIL] — Data source supports requirements [detail if FAIL]

### H: Mock Data Completeness
- H1: [PASS/FAIL] — Mock data described [detail if FAIL]
- H2: [PASS/FAIL] — Data characteristics specified [detail if FAIL]
- H3: [PASS/FAIL] — Mock data maps to data source [detail if FAIL]

---

## Failures Detail

[For each FAIL, provide:]

### [Check ID]: [Check name]
**Location:** [section number and heading in the spec]
**Expected:** [what should be there]
**Found:** [what was found, or "missing"]
```

---

## Rules

1. **Report only.** Never edit the spec. Cite section numbers and quote problematic text in failures.
2. **Only check what this skill defines.** No opinions on domain accuracy, writing quality, or extra requirements.
3. **Judge content, not formatting.** Correct info in non-standard markdown = PASS. Perfect formatting with empty/placeholder content = FAIL.
4. **All checks are binary PASS/FAIL.** No warnings or partial credit.
5. **Domain accuracy is out of scope.** Structural and rule conformance only.
