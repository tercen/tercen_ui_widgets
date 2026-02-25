---
name: phase-1-review-type3
description: Review a Phase 1 functional spec for a Type 3 (workflow manager) app. Checks three-panel layout, Status Panel sections, Header Panel modes, Content Panel stages, and workflow template. Produces a PASS/FAIL conformance report.
argument-hint: "[path to functional spec]"
disable-model-invocation: true
allowed-tools:
  - Read
  - Glob
  - Grep
  - Write
  - AskUserQuestion
---

**This file is READ-ONLY during reviews. Do NOT modify it.**

Review a Type 3 functional spec against all checks below. For design rules, read `_references/type3-design-summary.md` and `_references/global-rules.md`.

**Input:** Path to the Phase 1 spec (markdown). Use AskUserQuestion if not provided.

**Steps:** Read entire spec. Run checks A-J in order (PASS/FAIL only, no fixes). Write report to `_local/phase-1-conformance-report.md`.

---

## Check Group A: Document Structure

All 9 sections are required. Each must be present and contain meaningful content.

### A1: Section 1 — Overview
Must contain: 1.1 Purpose, 1.2 Users, 1.3 Scope (In/Out), 1.4 Launch Modes (table).

### A2: Section 2 — Domain Context
Must contain: 2.1 Background, 2.2 Workflow Template (step table + data flow), 2.3 Typical User Workflow.

### A3: Section 3 — Functional Requirements
Table with ID, Requirement, Priority (Must/Should/Could).

### A4: Section 4 — User Interface Components
Must contain: 4.1 App Structure (ASCII diagram), 4.2 Status Panel Sections, 4.3 Header Panel, 4.4 Content Panel Input Mode, 4.5 Content Panel Display Mode, 4.6 Running State.

### A5: Section 5 — Non-Functional Requirements
Table with at least one entry.

### A6: Section 6 — Feature Summary
Must Have / Should Have / Could Have tables.

### A7: Section 7 — Assumptions
Must contain: 7.1 Data Assumptions, 7.2 Environment Assumptions, 7.3 Mock Data.

### A8: Section 8 — Glossary
Table with Term and Definition. Must be present even if empty (with note).

### A9: App type identified as Type 3
The spec must explicitly identify the app as Type 3 (Workflow Manager).

---

## Check Group B: Header Metadata

### B1: App name in top-level heading
### B2: Version field present
### B3: Status field present
### B4: Last Updated field present
### B5: Reference field present
### B6: App Type field shows "Type 3"

---

## Check Group C: Layout Diagram

### C1: ASCII diagram present in Section 4.1

### C2: Three-panel structure shown
Diagram must show three panels: Status Panel (left), Header Panel (top-right), Content Panel (main-right).

### C3: Diagram shows Status Panel sections
All 5 Status Panel section names (ACTIONS, STATUS, CURRENT RUN, HISTORY, INFO) visible in diagram.

### C4: Diagram shows Header Panel
A Header Panel strip between the left panel and Content Panel.

### C5: Diagram matches sections
Every section in the diagram corresponds to a section in 4.2. No orphans.

---

## Check Group D: Status Panel Sections

### D1: All 5 sections present
Must have: ACTIONS, STATUS, CURRENT RUN, HISTORY, INFO — in that order.

### D2: Every section has icon and UPPERCASE label

### D3: ACTIONS section specifies buttons
Must define: Run, Stop, Reset (at minimum). Each must specify enabled/disabled conditions.

### D4: STATUS section specifies states
Must define state indicators for at least: Running, Waiting, Complete, Error.

### D5: CURRENT RUN section specifies parameters
Must list what parameters/files are shown during input.

### D6: HISTORY section specifies entry format
Must describe: run name, timestamp, status, click action.

### D7: INFO section present and last
Must be the last section with GitHub link.

---

## Check Group E: Header Panel

### E1: Header Panel modes defined
Must have a table or description covering all three modes: Input, Display, Running.

### E2: Input mode defined
Left zone: heading text. Right zone: primary action button label.

### E3: Display mode defined
Left zone: run identifier. Right zone: Re-Run, Export, Delete buttons.

### E4: Running mode defined
Both zones dimmed. No active buttons (Stop is on Status Panel).

---

## Check Group F: Content Panel

### F1: Input stages enumerated
Section 4.4 must define at least one input stage with heading, description, primary action, and form controls.

### F2: Input controls have required attributes
Every control must specify: name, type, default, range/options.

### F3: Only allowed control types used
All 11 types: dropdown, slider, range slider, toggle, number input, button, searchable input, text input, checkbox, radio, segmented button. Anything else is a FAIL.

### F4: Display mode layout described
Section 4.5 must describe the results layout.

### F5: Display export format specified
Must state what format(s) the Export button produces.

### F6: Running state described
Section 4.6 must describe what the user sees during execution.

---

## Check Group G: Workflow Template

### G1: Template identified
Section 2.2 must identify the workflow template by name.

### G2: Steps listed
Section 2.2 must list workflow steps with operator name, purpose, and user-input flag.

### G3: Data flow described
Section 2.2 must describe data flow between steps.

### G4: User-input steps match input stages
Steps flagged "User Input Required: Yes" must correspond to input stages in Section 4.4.

---

## Check Group H: Launch Modes

### H1: Launch modes table present
Section 1.4 must have a table with Standalone and In-project rows.

### H2: At least one mode supported
At least one launch mode must be "Yes".

### H3: Behaviour described for each supported mode
Each "Yes" mode must have a behaviour description.

---

## Check Group I: No Implementation Detail

### I1: No code
### I2: No framework references (Flutter, Provider, GetIt, etc.)
### I3: No pixel values or spacing tokens
### I4: No colour codes (except domain-specific)
### I5: No file paths or import statements
### I6: Mock data describes WHAT not HOW

---

## Check Group J: Mock Data Completeness

### J1: Mock data described
Section 7.3 must describe input data, result data, and multiple run datasets.

### J2: Real workflow data required
Mock data must come from a real completed workflow, not synthetic/generated data.

### J3: Multiple run datasets
Must specify 2-3 pre-built run datasets for history browsing.

### J4: Data maps to workflow steps
Must explain which workflow step outputs appear where in the app.

---

## Conformance Report Format

```markdown
# Phase 1 Type 3 Conformance Report

**Spec:** [filename]
**App Name:** [from heading]
**App Type:** Type 3
**Date:** [review date]

## Summary

| Result | Count |
|--------|-------|
| PASS | [n] |
| FAIL | [n] |
| **Total** | [n] |

**Verdict:** [CONFORMING / NON-CONFORMING]

---

## Results

### A: Document Structure
- A1–A9: [PASS/FAIL each]

### B: Header Metadata
- B1–B6: [PASS/FAIL each]

### C: Layout Diagram
- C1–C5: [PASS/FAIL each]

### D: Status Panel Sections
- D1–D7: [PASS/FAIL each]

### E: Header Panel
- E1–E4: [PASS/FAIL each]

### F: Content Panel
- F1–F6: [PASS/FAIL each]

### G: Workflow Template
- G1–G4: [PASS/FAIL each]

### H: Launch Modes
- H1–H3: [PASS/FAIL each]

### I: No Implementation Detail
- I1–I6: [PASS/FAIL each]

### J: Mock Data Completeness
- J1–J4: [PASS/FAIL each]

---

## Failures Detail

### [Check ID]: [Check name]
**Location:** [section]
**Expected:** [what should be there]
**Found:** [what was found]
```

---

## Rules for the Reviewer

1. **Be precise.** Cite section numbers and quote text in failures.
2. **Only check what this skill defines.** No invented requirements, no domain-accuracy judgments.
3. **PASS or FAIL only.** No warnings, no partial credit. Judge content, not formatting.
4. **Report only — never fix the spec.**
