# Pattern: Functional Specification Discovery

**Purpose**: Guide Claude through gathering requirements to generate a complete functional specification.

**When to use**: Development Mode, Phase 2 (Planning), before writing any code.

---

## Overview

Instead of maintaining sample functional specifications, Claude asks discovery questions to collaboratively build the spec with the user. The answers become the specification content.

This pattern ensures:

- All necessary information is gathered before implementation
- No assumptions are made about domain-specific requirements
- The resulting spec follows a consistent structure
- Nothing is missed

---

## Specification Structure

A complete functional specification has 8 sections. Claude must gather information for ALL sections before implementation.

| Section | Purpose |
| ------- | ------- |
| 1. Overview | What and why |
| 2. Domain Context | Background knowledge needed |
| 3. Functional Requirements | What the app must do |
| 4. User Interface Components | Screen structure and behaviors |
| 5. Non-Functional Requirements | Performance, compatibility, usability |
| 6. Feature Summary | Quick reference checklist |
| 7. Assumptions | What we're taking for granted |
| 8. Glossary | Domain terminology |

---

## Discovery Questions

Claude asks these questions to populate each section. Not all questions apply to every app - use judgment.

### Section 1: Overview

**Purpose**

> What problem does this app solve?
> Who are the users?
> When/why do they use it?

**Scope - In**

> What features are required?
> What must the app do?

**Scope - Out**

> What is explicitly NOT in scope?
> What should this app NOT do?
> (Important to prevent scope creep)

---

### Section 2: Domain Context

**Domain/System**

> What domain, instrument, or system does this relate to?
> Is there existing documentation I should know about?

**Terminology**

> What domain-specific terms should I understand?
> (Answers populate the Glossary)

**Use Case**

> Walk me through a typical user workflow.
> What triggers the user to open this app?
> What do they do, and what outcome do they expect?

---

### Section 3: Functional Requirements

**Data Source**

> Where does the data come from?
> - Tercen workflow projections (which columns?)
> - External files (what format?)
> - User input
> - Other

**Data Format**

> What format is the data?
> (JSON, CSV, images, binary, etc.)
> What metadata is associated with it?

**Display Requirements**

> How should data be displayed?
> - Grid / table
> - Chart / visualization
> - List
> - Images
> - Other

**Filtering/Controls**

> What filters or controls does the user need?
> What should the default values be?

**Interactions**

> What user interactions are required?
> - Click actions
> - Hover behaviors
> - Selection
> - Drag/drop
> - Other

**Output**

> Does the app write data back to Tercen?
> Does it export anything?
> Or is it view-only?

---

### Section 4: User Interface Components

**Main Screen**

> What components appear on the main screen?
> How is the content organized?

**Left Panel**

> What sections are needed in the left panel?
> What controls go in each section?
> (Refer to left-panel.md pattern for structure)

**Detail/Secondary Views**

> Are there any detail views or secondary screens?
> What triggers them? (click, button, etc.)
> What do they show?

**Component Behaviors**

> Any specific behaviors for UI components?
> (e.g., "filter changes should not require full reload")

---

### Section 5: Non-Functional Requirements

**Performance**

> Any performance requirements?
> Expected data size? (number of items, file sizes)
> Acceptable load times?

**Compatibility**

> Must run as Tercen web operator? (usually yes)
> Any specific browser requirements?

**Usability**

> Any accessibility requirements?
> Loading state indicators needed?
> Error message requirements?

---

### Section 6: Feature Summary

After gathering requirements, Claude compiles a feature checklist:

```markdown
| Feature | Required |
| ------- | -------- |
| [Feature 1] | Yes/No |
| [Feature 2] | Yes/No |
| ... | ... |
```

---

### Section 7: Assumptions

**Data Assumptions**

> What can we assume about input data format?
> Is the data always well-formed?
> What if data is missing or malformed?

**Environment Assumptions**

> What can we assume about the user's environment?
> Permissions? Network? Browser capabilities?

**Mock Data**

> For mock implementation, what data will be provided?
> Will the user supply sample data, or should Claude generate synthetic data?

---

### Section 8: Glossary

Populated from Section 2 (Domain Context) terminology questions.

```markdown
| Term | Definition |
| ---- | ---------- |
| [Term 1] | [Definition] |
| [Term 2] | [Definition] |
| ... | ... |
```

---

## Discovery Process

### Step 1: Initial Gathering

Ask questions from Sections 1-3 first (Overview, Domain, Functional Requirements). These establish the foundation.

### Step 2: UI Details

Once the "what" is clear, ask Section 4 questions (UI Components).

### Step 3: Constraints

Ask Sections 5-7 questions (Non-Functional, Features, Assumptions).

### Step 4: Draft Specification

Write a complete specification document with all 8 sections.

### Step 5: User Review

Present the draft to the user for review and refinement.

### Step 6: Approval

Once approved, the specification becomes the implementation guide.

---

## Question Efficiency

**DO NOT** ask all questions in a single message. Instead:

1. Start with Purpose and Scope (3-4 questions)
2. Based on answers, ask relevant follow-up questions
3. Skip questions that don't apply
4. Consolidate related questions

**Example flow**:

```
Claude: "What problem does this app solve, and who uses it?"
User: "It's a volcano plot viewer for differential expression data"
Claude: "Got it. Where does the data come from - Tercen projections,
         uploaded files, or somewhere else?"
User: "Tercen projections - .x for fold change, .y for p-value, labels for genes"
Claude: "What controls does the user need? Any filtering or threshold adjustments?"
...
```

---

## Output Format

The final specification should follow this format:

```markdown
# [App Name] - Functional Specification

**Version:** 1.0.0
**Status:** Draft / Active
**Last Updated:** [Date]

---

## 1. Overview

### 1.1 Purpose
[From discovery]

### 1.2 Scope
**In Scope:**
- [Feature 1]
- [Feature 2]

**Out of Scope:**
- [Exclusion 1]
- [Exclusion 2]

---

## 2. Domain Context
[From discovery]

---

## 3. Functional Requirements

| ID | Requirement | Priority |
|----|-------------|----------|
| FR-01 | [Requirement] | Must/Should/Could |
| FR-02 | [Requirement] | Must/Should/Could |

---

## 4. User Interface Components
[From discovery]

---

## 5. Non-Functional Requirements

| ID | Requirement |
|----|-------------|
| NFR-01 | [Requirement] |

---

## 6. Feature Summary

| Feature | Required |
|---------|----------|
| [Feature] | Yes/No |

---

## 7. Assumptions
[From discovery]

---

## 8. Glossary

| Term | Definition |
|------|------------|
| [Term] | [Definition] |
```

---

## Checklist

Before proceeding to implementation:

- [ ] Section 1 (Overview) complete - purpose and scope defined
- [ ] Section 2 (Domain) complete - terminology understood
- [ ] Section 3 (Functional) complete - all requirements gathered
- [ ] Section 4 (UI) complete - screen structure defined
- [ ] Section 5 (Non-Functional) complete - constraints documented
- [ ] Section 6 (Features) complete - summary checklist created
- [ ] Section 7 (Assumptions) complete - expectations documented
- [ ] Section 8 (Glossary) complete - terms defined
- [ ] User has reviewed and approved the specification

---

## Related Documents

- [README.md](../README.md) - Development Mode workflow
- [Pattern: App Frame](app-frame.md) - UI structure patterns
- [Pattern: Left Panel](left-panel.md) - Left panel patterns
