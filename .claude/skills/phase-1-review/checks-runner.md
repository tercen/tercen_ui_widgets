# Phase 1 Review — Runner Widget Checks

**READ-ONLY — do not modify this file.**

These checks apply to runner widgets (three-panel layout: status panel + header panel + content panel). They are loaded by `SKILL.md` after kind detection.

---

## Check Group A: Document Structure

All 9 sections required with meaningful content (not empty or "TBD").

### A1: Section 1 — Overview
Must contain: 1.1 Purpose, 1.2 Users, 1.3 Scope (In/Out), 1.4 Launch Modes (table).

### A2: Section 2 — Domain Context
Must contain: 2.1 Background, 2.2 Workflow Template (step table + data flow), 2.3 Typical User Workflow.

### A3: Section 3 — Functional Requirements
Table with ID, Requirement, Priority (Must/Should/Could).

### A4: Section 4 — User Interface Components
Must contain: 4.1 Widget Structure (ASCII diagram), 4.2 Status Panel Sections, 4.3 Header Panel, 4.4 Content Panel Input Mode, 4.5 Content Panel Display Mode, 4.6 Running State.

### A5: Section 5 — Non-Functional Requirements
Table with at least one entry.

### A6: Section 6 — Feature Summary
Must Have / Should Have / Could Have tables.

### A7: Section 7 — Assumptions
Must contain: 7.1 Data Assumptions, 7.2 Environment Assumptions, 7.3 Mock Data.

### A8: Section 8 — Glossary
Table with Term and Definition. Must be present even if empty (with note).

### A9: Widget kind identified as runner
The spec must explicitly identify the widget as a runner (workflow manager).

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

## Check Group J: Mock Data Completeness

### J1: Mock data described
Section 7.3 must describe input data, result data, and multiple run datasets.

### J2: Real workflow data required
Mock data must come from a real completed workflow, not synthetic/generated data.

### J3: Multiple run datasets
Must specify 2-3 pre-built run datasets for history browsing.

### J4: Data maps to workflow steps
Must explain which workflow step outputs appear where in the widget.

---

## Runner Report Sections

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
- A9: [PASS/FAIL] — Widget kind identified as runner [detail if FAIL]

### C: Layout Diagram
- C1: [PASS/FAIL] — ASCII diagram present [detail if FAIL]
- C2: [PASS/FAIL] — Three-panel structure shown [detail if FAIL]
- C3: [PASS/FAIL] — Diagram shows Status Panel sections [detail if FAIL]
- C4: [PASS/FAIL] — Diagram shows Header Panel [detail if FAIL]
- C5: [PASS/FAIL] — Diagram matches sections [detail if FAIL]

### D: Status Panel Sections
- D1: [PASS/FAIL] — All 5 sections present [detail if FAIL]
- D2: [PASS/FAIL] — Every section has icon and UPPERCASE label [detail if FAIL]
- D3: [PASS/FAIL] — ACTIONS section specifies buttons [detail if FAIL]
- D4: [PASS/FAIL] — STATUS section specifies states [detail if FAIL]
- D5: [PASS/FAIL] — CURRENT RUN section specifies parameters [detail if FAIL]
- D6: [PASS/FAIL] — HISTORY section specifies entry format [detail if FAIL]
- D7: [PASS/FAIL] — INFO section present and last [detail if FAIL]

### E: Header Panel
- E1: [PASS/FAIL] — Header Panel modes defined [detail if FAIL]
- E2: [PASS/FAIL] — Input mode defined [detail if FAIL]
- E3: [PASS/FAIL] — Display mode defined [detail if FAIL]
- E4: [PASS/FAIL] — Running mode defined [detail if FAIL]

### F: Content Panel
- F1: [PASS/FAIL] — Input stages enumerated [detail if FAIL]
- F2: [PASS/FAIL] — Input controls have required attributes [detail if FAIL]
- F3: [PASS/FAIL] — Only allowed control types [detail if FAIL]
- F4: [PASS/FAIL] — Display mode layout described [detail if FAIL]
- F5: [PASS/FAIL] — Display export format specified [detail if FAIL]
- F6: [PASS/FAIL] — Running state described [detail if FAIL]

### G: Workflow Template
- G1: [PASS/FAIL] — Template identified [detail if FAIL]
- G2: [PASS/FAIL] — Steps listed [detail if FAIL]
- G3: [PASS/FAIL] — Data flow described [detail if FAIL]
- G4: [PASS/FAIL] — User-input steps match input stages [detail if FAIL]

### H: Launch Modes
- H1: [PASS/FAIL] — Launch modes table present [detail if FAIL]
- H2: [PASS/FAIL] — At least one mode supported [detail if FAIL]
- H3: [PASS/FAIL] — Behaviour described for each supported mode [detail if FAIL]

### J: Mock Data Completeness
- J1: [PASS/FAIL] — Mock data described [detail if FAIL]
- J2: [PASS/FAIL] — Real workflow data required [detail if FAIL]
- J3: [PASS/FAIL] — Multiple run datasets [detail if FAIL]
- J4: [PASS/FAIL] — Data maps to workflow steps [detail if FAIL]
```
