# Phase 1 Review — Panel Widget Checks

**READ-ONLY — do not modify this file.**

These checks apply to panel widgets (two-panel layout: left panel + main content). They are loaded by `SKILL.md` after kind detection.

---

## Check Group A: Document Structure

All 8 sections required with meaningful content (not empty or "TBD").

### A1: Section 1 — Overview
Subsections: **1.1 Purpose** (paragraph on what the widget does), **1.2 Users**, **1.3 Scope** (explicit "In Scope" / "Out of Scope" lists).

### A2: Section 2 — Domain Context
Subsections: **2.1 Background**, **2.2 Data Source** (table with Column/Description/Example; must describe Tercen projections like `.y`, `.ci`, `.ri`, `.x`, labels, colours and data characteristics: ranges, counts, sparsity), **2.3 Typical Workflow** (numbered steps).

### A3: Section 3 — Functional Requirements
Requirements table with columns: ID, Requirement, Priority (Must / Should / Could).

### A4: Section 4 — User Interface Components
Subsections: **4.1 Widget Structure** (ASCII layout — see Group C), **4.2 Left Panel Sections** (controls — see Group D), **4.3 Main Panel**.

### A5: Section 5 — Non-Functional Requirements
Table with ID and Requirement columns. At least one entry.

### A6: Section 6 — Feature Summary
Categorized feature tables: **Must Have**, **Should Have**, **Could Have**. Each with Feature and Status columns.

### A7: Section 7 — Assumptions
Subsections: **7.1 Data Assumptions**, **7.2 Environment Assumptions**, **7.3 Mock Data** (available data, characteristics, mapping to Section 2.2).

### A8: Section 8 — Glossary
Table with Term and Definition columns. Section must exist even if no terms apply (add a note).

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

## Panel Report Sections

Insert the following check groups into the conformance report Results section (between Header Metadata and No Implementation Detail):

```
### A: Document Structure
- A1: [PASS/FAIL] — Section 1: Overview [detail if FAIL]
- A2: [PASS/FAIL] — Section 2: Domain Context [detail if FAIL]
- A3: [PASS/FAIL] — Section 3: Functional Requirements [detail if FAIL]
- A4: [PASS/FAIL] — Section 4: User Interface Components [detail if FAIL]
- A5: [PASS/FAIL] — Section 5: Non-Functional Requirements [detail if FAIL]
- A6: [PASS/FAIL] — Section 6: Feature Summary [detail if FAIL]
- A7: [PASS/FAIL] — Section 7: Assumptions [detail if FAIL]
- A8: [PASS/FAIL] — Section 8: Glossary [detail if FAIL]

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
```
