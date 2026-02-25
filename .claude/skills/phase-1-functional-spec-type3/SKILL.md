---
name: phase-1-functional-spec-type3
description: Write a functional specification for a new Tercen Type 3 (workflow manager) Flutter web app. Produces a complete spec document covering Status Panel, Header Panel, Content Panel modes, workflow template, and run management — with no code.
argument-hint: "[app name or description]"
disable-model-invocation: true
---

**READ-ONLY. Do NOT modify. Log gaps to `_issues/session-log.md` and continue.**

Produce a Type 3 functional spec document. Do NOT write any code.

For design rules: `_references/type3-design-summary.md` and `_references/global-rules.md`.

---

## Type 3 Design Constraints

MUST follow these rules when designing the UI.

1. **Three-panel layout:** Status Panel (left) + Header Panel (top-right, 48px) + Content Panel (main-right, scrollable).
2. **Status Panel has 5 sections** in order: ACTIONS, STATUS, CURRENT RUN, HISTORY, INFO. Each has an icon and UPPERCASE label.
3. **Header Panel** has two zones: left (context label) and right (action buttons). Content changes by mode.
4. **Content Panel** switches between Input mode and Display mode. The app drives mode transitions, not the user.
5. **Two hard states:** Running (app doing work) and Waiting (needs input or showing results).
6. **Running state overlay:** AbsorbPointer + dimming on Header + Content. Status Panel stays active.
7. **App is a runner layer.** Can start, stop, provide inputs. Cannot modify workflow structure.
8. **Available control types** (exactly 11): dropdown, slider, range slider, toggle, number input, button, searchable input, text input, checkbox, radio, segmented button.
9. **INFO section is mandatory.** Always at bottom of Status Panel.
10. **No nesting.** No apps within apps, no sub-panels.

---

## Output Rules

- The spec describes WHAT the app does, never HOW it is implemented.
- No Dart code, no pseudo-code, no implementation approach.
- No pixel values, spacing tokens, or colour codes (except domain-specific colours).
- No references to Flutter widgets, Provider, GetIt, or any framework.
- Mock data requirements describe WHAT data is needed, not how to load it.

---

## Spec Template — Type 3

Every Type 3 functional spec follows this structure. All 9 sections are required.

```markdown
# [App Name] - Functional Specification

**Version:** 1.0.0
**Status:** Draft
**Last Updated:** [Date]
**App Type:** Type 3 (Workflow Manager)
**Reference**: [Source material — workflow, screenshots, description, etc.]

---

## 1. Overview

### 1.1 Purpose
[What problem does this app solve? What workflow does it wrap?]

### 1.2 Users
[Who uses this app?]

### 1.3 Scope

**In Scope:**
- [Feature 1]

**Out of Scope:**
- [Exclusion 1]

### 1.4 Launch Modes

| Mode | Supported | Behaviour |
|------|-----------|-----------|
| Standalone | Yes / No | [What happens — creates project, full setup flow?] |
| In-project | Yes / No | [What happens — detects existing project, skips setup?] |

---

## 2. Domain Context

### 2.1 Background
[Domain knowledge needed to understand this app.]

### 2.2 Workflow Template

**Template name:** [Name of the Tercen workflow template]
**Source:** [Where the template lives / how it's identified]

**Workflow steps:**

| Step | Operator | Purpose | User Input Required? |
|------|----------|---------|---------------------|
| 1 | [Operator name] | [What it does] | Yes / No |
| 2 | [Operator name] | [What it does] | Yes / No |

**Data flow:**
1. [Input data] → Step 1 → [Output 1]
2. [Output 1] → Step 2 → [Output 2]
3. ...

### 2.3 Typical User Workflow
1. [Step 1 — what the user does]
2. [Step 2]
3. ...

---

## 3. Functional Requirements

| ID | Requirement | Priority |
|----|-------------|----------|
| FR-01 | [Requirement] | Must / Should / Could |

---

## 4. User Interface Components

### 4.1 App Structure

[ASCII layout diagram. Example:]

┌─ Status Panel ─┬─ Header Panel ───────────────────┐
│ ACTIONS         │  [heading]            [action]    │
│ STATUS          ├───────────────────────────────────┤
│ CURRENT RUN     │                                   │
│ HISTORY         │  Content Panel                    │
│ INFO            │                                   │
└─────────────────┴───────────────────────────────────┘

### 4.2 Status Panel Sections

#### Section 1: ACTIONS
Icon: [icon description]

| Button | Enabled When | Action |
|--------|-------------|--------|
| Run | [condition] | [what happens] |
| Stop | [condition] | [what happens] |
| Reset | [condition] | [what happens] |

#### Section 2: STATUS

| State | Indicator | Label |
|-------|-----------|-------|
| Running | [colour/icon] | [step description] |
| Waiting | [colour/icon] | [what's needed] |
| Complete | [colour/icon] | "Analysis complete" |
| Error | [colour/icon] | [error message source] |

#### Section 3: CURRENT RUN

| Parameter | Source | Format |
|-----------|--------|--------|
| [param name] | [user input / auto-detected] | [how displayed] |

#### Section 4: HISTORY

| Field | Description |
|-------|-------------|
| Run name | [how generated — e.g., workflow clone name] |
| Timestamp | [format] |
| Status | complete / error / stopped |
| Click action | Opens Display mode for that run |

#### Section 5: INFO
Icon: info icon
GitHub repository link. App name and version.

### 4.3 Header Panel

| Mode | Left Zone | Right Zone |
|------|-----------|------------|
| Input | [heading per input stage] | [primary action label] |
| Display | [run identifier format] | Re-Run, Export, Delete |
| Running | [dimmed — keeps current label] | [dimmed — no active buttons] |

### 4.4 Content Panel — Input Mode

[For each input stage/screen:]

#### Input Stage 1: [Name]

**Heading:** [text shown in Header Panel]
**Description:** [optional context text at top of Content Panel]
**Primary action:** [button label, e.g., "Continue", "Upload"]

**Form (left column):**

| Section | Control | Type | Default | Range/Options |
|---------|---------|------|---------|---------------|
| [SECTION] | [name] | dropdown/slider/etc. | [default] | [range/options] |

**Visualization (right column, optional):**
[What data is shown to help the user. Read-only. Source: which workflow step output.]

#### Input Stage N: [Name]
[Same structure]

### 4.5 Content Panel — Display Mode

**Layout:**
[Describe the results layout — sections, charts, tables, images, etc.]

**Display controls (inline, optional):**

| Control | Type | Purpose |
|---------|------|---------|
| [name] | [type] | [what it filters/toggles in the results] |

**Export format:** [PDF / CSV / images / etc.]

### 4.6 Running State

[What the user sees during execution:]
- Running overlay with animation
- Status Panel shows progress
- Stop button active
- [Any app-specific running behaviour]

---

## 5. Non-Functional Requirements

| ID | Requirement |
|----|-------------|
| NFR-01 | [Requirement] |

---

## 6. Feature Summary

### Must Have
| Feature | Status |
|---------|--------|
| [Feature] | Planned |

### Should Have / Could Have
| Feature | Priority | Status |
|---------|----------|--------|
| [Feature] | Should / Could | Planned |

---

## 7. Assumptions

### 7.1 Data Assumptions
- [What we assume about input data files]
- [Template workflow pre-conditions]

### 7.2 Environment Assumptions
- [Browser, screen size, network, etc.]

### 7.3 Mock Data

**Input data (for Input mode):**
- [Files/data used in each input stage]
- [Source: real workflow run or generated]

**Result data (for Display mode):**
- [Output files/tables from completed workflow]
- [Multiple run datasets for history browsing (2-3 runs)]

**How mock data maps to workflow steps:**
- Step 1 output → [where it appears in the app]
- Step 2 output → [where it appears]

---

## 8. Glossary

| Term | Definition |
|------|------------|
| [Term] | [Definition] |
```

---

## Discovery Process

Gather information in this order. Adapt to the input source.

### Round 1: Purpose and Workflow

- What does this app do? Who uses it?
- What Tercen workflow template does it wrap?
- What are the workflow steps? Which need user input?
- What are the workflow inputs and outputs?
- Standalone launch, in-project launch, or both?
- Is there existing code, screenshots, or a running example?

### Round 2: Input Stages

- How many input stages are there?
- What must the user provide at each stage? (files, settings, selections)
- Which operator properties are exposed to the user?
- Do later stages depend on earlier results? (e.g., channel selection after data upload)
- For each control: type, default, range/options?

### Round 3: Display and Results

- What does the completed workflow produce?
- How should results be presented? (charts, tables, images, downloads)
- What display controls are needed? (filters, view toggles)
- What export formats are needed?
- What does the run identifier look like?

### Round 4: Status and History

- What progress information is available during execution?
- How granular is the step tracking?
- How should errors be displayed?
- What run metadata should appear in CURRENT RUN and HISTORY?

### Round 5: Draft and Review

- Write the complete spec following the template above.
- Present to user for review.
- Iterate until approved.

### MCP Integration (Optional)

If the Tercen MCP server (`tercenctl mcp`) is available:
1. User provides a workflow ID or project ID
2. Use MCP tools to inspect the workflow: steps, operators, properties
3. Present the workflow structure and ask which settings to expose
4. Build Input mode specs from actual operator properties and outputs

---

## Question Efficiency

- Do NOT dump all questions at once. Ask 3-4 per round.
- Skip questions already answered by provided material.
- When reviewing existing code/workflows, proactively identify gaps.
- Consolidate related questions.

---

## Checklist

Before completing Phase 1:

- [ ] All 9 spec sections populated
- [ ] ASCII layout diagram with three-panel structure
- [ ] All 5 Status Panel sections specified with icons and UPPERCASE labels
- [ ] Header Panel modes defined (Input / Display / Running)
- [ ] All input stages enumerated with controls (type, default, range)
- [ ] Display mode layout described
- [ ] Launch modes clarified (standalone / in-project / both)
- [ ] Workflow template identified with step list
- [ ] Running state behaviour described
- [ ] Mock data requirements specify real workflow data (2-3 runs)
- [ ] No implementation detail (no code, no framework references)
- [ ] INFO section included
- [ ] User has reviewed and approved
