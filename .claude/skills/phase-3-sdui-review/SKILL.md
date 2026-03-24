---
name: phase-3-sdui-review
description: Review an SDUI JSON template in catalog.json for conformance against template structure, DataSource wiring, Tier 1 primitive usage, and intent routing. Produces a PASS/FAIL report. Use after an SDUI template integration is complete.
argument-hint: "[widget type name in catalog.json]"
disable-model-invocation: true
allowed-tools:
  - Read
  - Glob
  - Grep
  - Write
  - AskUserQuestion
---

**This file is READ-ONLY during reviews. Do NOT modify it.**

## Inputs

- **Widget type name** — the `metadata.type` value of the entry in `catalog.json`
- **Functional spec** — the Phase 1 output document (markdown file), if available

If the widget type is not provided, ask the user.

---

## Workflow

1. Read `catalog.json`. Find the entry matching the widget type name.
2. If a functional spec is provided, read it. Cross-reference data sources (Section 1.4) against `DataSource` nodes.
3. Run all check groups below.
4. Produce the conformance report and save to `_local/phase-3-sdui-conformance-report.md` in the project root.

---

## Check Group A: Metadata Structure

### A1: Required metadata fields

Entry must have `metadata` with: `type` (string), `tier` (number, should be 2), `description` (non-empty string).

### A2: Props definition

If the template uses `{{props.X}}` bindings, `metadata.props` must declare each `X` with `type` and `description`.

### A3: handlesIntent consistency

If `metadata.handlesIntent` is present:
- Each entry must have `intent` (string), `propsMap` (object), `windowTitle` (string), `windowSize` (string).
- `windowSize` must be one of: `small`, `medium`, `large`, `column`, `row`, `full`.
- Every value in `propsMap` must correspond to a key in `metadata.props`.

### A4: Unique type name

No other entry in `catalog.json` may have the same `metadata.type`.

---

## Check Group B: Template Structure

### B1: Root node has id and type

The `template` object must have `type` (string) and `id` (string).

### B2: All nodes have unique IDs

Every node in the template tree must have a unique `id`. Collect all IDs recursively from `children` arrays. Duplicates are a FAIL.

### B3: IDs use widgetId prefix

All `id` values should use the `{{widgetId}}-suffix` pattern. IDs that are hardcoded strings (without `{{widgetId}}`) are a FAIL — they will collide when the same template is instantiated multiple times.

### B4: Valid Tier 1 types

Every `type` value in the template tree must be one of the known Tier 1 primitives:

**Layout:** `Row`, `Column`, `Container`, `Expanded`, `SizedBox`, `Center`, `Spacer`, `ListView`, `Grid`, `Card`, `Padding`
**Display:** `Text`, `SelectableText`, `Icon`, `Divider`, `Chip`, `CircleAvatar`, `Image`, `Tooltip`, `ProgressBar`, `Placeholder`, `LoadingIndicator`
**Interactive:** `TextField`, `ElevatedButton`, `TextButton`, `IconButton`, `Switch`, `Checkbox`, `DropdownButton`
**Behaviour:** `DataSource`, `ForEach`, `Action`, `ReactTo`, `Conditional`, `PromptRequired`, `StateHolder`, `Sort`, `Filter`
**Domain:** `DataTable`, `DirectedGraph`, `ImageViewer`, `TabbedImageViewer`, `TabbedDataTable`
**Orchestrator:** `ChatPanel`
**Tier 2 references:** Any `metadata.type` from another entry in `catalog.json` (templates can compose other templates)

Any unrecognized type is a FAIL.

---

## Check Group C: DataSource Nodes

### C1: Service and method are specified

Every `DataSource` node must have `props.service` (string) and `props.method` (string).

### C2: Known services

`props.service` must be one of: `tableSchemaService`, `fileService`, `operatorContext`, `projectService`, `teamService`, `workflowService`, `userService`, `projectDocumentService`, `operatorService`.

### C3: Known methods for service

Cross-reference `props.method` against known methods:

- **tableSchemaService:** `select`, `selectCSV`, `getStepImages`, `get`, `list`
- **fileService:** `download`, `downloadUrl`, `get`, `list`
- **operatorContext:** `saveTable`, `saveTables`
- **workflowService:** `get`, `list`, `getWorkflowGraph` + `findStartKeys`/`findKeys` variants
- **projectService:** `get`, `list`, `create` + `findStartKeys`/`findKeys` variants
- **userService:** `get`, `list`

If the method is not in this list, flag as WARNING (not FAIL) — it may be a newly added dispatcher method. Note: use `discover_methods()` to verify if possible.

### C4: Args are provided

`props.args` must be present and be an array. Empty args `[]` is acceptable only for parameterless methods.

### C5: Loading/error/ready states

Every `DataSource` node should have child `Conditional` nodes covering at least `{{loading}}` and `{{ready}}` states. Missing error handling is a WARNING.

---

## Check Group D: PromptRequired

### D1: Fields match props

If `PromptRequired` is used, each field `name` must match a prop that the template bindings reference.

### D2: PromptRequired wraps DataSource

`PromptRequired` must be an ancestor of any `DataSource` that uses the prompted prop in its `args`. A `DataSource` referencing `{{workflowId}}` without a `PromptRequired` providing `workflowId` — and without the prop being `required: false` with a default or provided via `handlesIntent` — is a FAIL.

---

## Check Group E: ForEach Nodes

### E1: Items binding

Every `ForEach` node must have `props.items` referencing a data array (e.g., `{{data.projects}}`).

### E2: Child IDs use index

Children of `ForEach` should use `{{_index}}` in their `id` to ensure uniqueness across iterations. Missing index in IDs is a WARNING.

---

## Check Group F: Home Configuration

### F1: Valid home references

If `catalog.json` has a `"home"` key, each window's `type` must match a `metadata.type` in the `widgets` array, or be a Tier 1 primitive like `ChatPanel`.

### F2: Valid size values

Each home window's `size` (if present) must be one of: `small`, `medium`, `large`, `column`, `row`, `full`.

### F3: Valid align values

Each home window's `align` (if present) must be one of: `center`, `left`, `right`, `top`, `bottom`.

---

## Check Group G: Spec Cross-Reference

N/A if no functional spec is provided.

### G1: Data sources mapped

Each data source listed in spec Section 1.4 should have a corresponding `DataSource` node in the template.

### G2: Events mapped

Each emitted event in the spec's EventBus section should appear in `metadata.emittedEvents`.

### G3: Intents mapped

If the spec describes opening in response to user actions from other widgets, `metadata.handlesIntent` should have corresponding entries.

---

## Report Format

```markdown
# Phase 3 SDUI Conformance Report

**Widget:** [type name]
**Date:** [date]
**Verdict:** PASS / FAIL

## Results

### Group A: Metadata Structure
- A1: [PASS/FAIL] [detail if FAIL]
- A2: [PASS/FAIL/N/A]
- A3: [PASS/FAIL/N/A]
- A4: [PASS/FAIL]

### Group B: Template Structure
- B1: [PASS/FAIL]
- B2: [PASS/FAIL]
- B3: [PASS/FAIL]
- B4: [PASS/FAIL]

### Group C: DataSource Nodes
- C1: [PASS/FAIL/N/A]
- C2: [PASS/FAIL/N/A]
- C3: [PASS/FAIL/WARNING/N/A]
- C4: [PASS/FAIL/N/A]
- C5: [PASS/FAIL/WARNING/N/A]

### Group D: PromptRequired
- D1: [PASS/FAIL/N/A]
- D2: [PASS/FAIL/N/A]

### Group E: ForEach Nodes
- E1: [PASS/FAIL/N/A]
- E2: [PASS/WARNING/N/A]

### Group F: Home Configuration
- F1: [PASS/FAIL/N/A]
- F2: [PASS/FAIL/N/A]
- F3: [PASS/FAIL/N/A]

### Group G: Spec Cross-Reference
- G1: [PASS/FAIL/N/A]
- G2: [PASS/FAIL/N/A]
- G3: [PASS/FAIL/N/A]

## Issues (if FAIL)

1. [Specific issue with fix guidance]
2. ...
```

Any single FAIL in groups A–E makes the overall verdict FAIL. Group F and G failures are WARNINGs unless they indicate a broken reference.
