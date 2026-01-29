# Issue #8: Mandatory Development Workflow

**Category**: Process / Planning

**Severity**: High - Prevents costly mistakes

## Problem

Developers skip planning phases and jump directly into coding:
- Requirements misunderstood
- Wrong technical approaches chosen
- Wasted implementation effort
- Missing critical considerations (like CORS, index.html, etc.)

## Impact

Real projects have experienced:
- Authentication issues (manual HTTP instead of sci_tercen_client)
- URL parsing problems (query params instead of path segments)
- Deployment confusion (index.html base href, build/web/ not committed)
- Hot reload time waste (expecting it to work)

**All of these could have been prevented with proper planning.**

## Mandatory Process

### Phase 1: Enter Plan Mode

```
User: "Add dark mode to the app"

Claude: [MUST call EnterPlanMode tool FIRST]
```

**NEVER start coding without plan mode** for non-trivial features.

### Phase 2: Product Specification

**Questions to Answer**:
- What are we building?
- Why are we building it?
- Who will use it?
- What are the success criteria?
- What are the constraints?

**Document**:
- Use cases
- User stories
- Success criteria
- Assumptions

### Phase 3: Technical Specification

**Questions to Answer**:
- How will we build it?
- Which patterns/repositories to reference?
- What files will change?
- What are the risks?
- What are the dependencies?

**Document**:
- Technical approach
- Repository references (auto-fetch with `gh`)
- File changes
- Risk mitigation
- Testing strategy

### Phase 4: Implementation Plan

**Breakdown**:
- Step-by-step tasks
- Verification strategy
- Checklist of requirements

**Example**:

```markdown
## Implementation Plan

1. [x] Review sci_tercen_client authentication pattern
2. [x] Create TercenUrlParser class
3. [ ] Implement standalone mode URL parsing
4. [ ] Implement workflow mode URL parsing
5. [ ] Add debug logging
6. [ ] Test both modes locally
7. [ ] Test in Tercen deployment
8. [ ] Verify with different URL patterns
```

### Phase 5: User Approval

```
Claude: [Calls ExitPlanMode tool]

User: [Reviews plan, approves or requests changes]

Claude: [ONLY THEN begins implementation]
```

### Phase 6: Implementation

Follow the approved plan systematically:
- Use TodoWrite tool to track progress
- Mark tasks complete as you go
- Verify each step
- Don't deviate from plan without discussion

## Enforcement

### Claude Self-Check

Before writing any code:

```
Is this trivial? (typo fix, single-line change)
  └─ Yes → Skip planning, just fix it
  └─ No → ENTER PLAN MODE
      ├─ Write Product Spec
      ├─ Write Technical Spec
      ├─ Write Implementation Plan
      ├─ Get user approval
      └─ Then implement
```

### User Reminder

If user says "just write the code":

```
Claude: "⚠️ WORKFLOW REMINDER: Our standard process requires:
1. Plan Mode entry
2. Product Specification
3. Technical Specification
4. Implementation Plan
5. User approval
6. Code implementation

Skipping planning phases often leads to rework.

Should we follow the proper workflow, or proceed directly to implementation?"
```

## Trivial vs Non-Trivial

### TRIVIAL (skip workflow)

- Typo fixes
- Comment additions
- Single-line obvious changes
- Variable renames (single file)
- Console.log additions for debugging

### NON-TRIVIAL (MUST use workflow)

- New features
- Multi-file changes
- Architecture decisions
- API integrations
- UI implementations
- Authentication changes
- Deployment modifications
- Anything that could break existing functionality

## Examples

### Example 1: Authentication Feature

```
User: "Add Tercen authentication"

❌ WRONG:
Claude: [Immediately starts writing code]

✅ CORRECT:
Claude: [Calls EnterPlanMode]
Claude: [Product Spec]
  - What: Web app authentication with Tercen platform
  - Why: Access Tercen API for file downloads
  - Success: User authenticated, can call API

Claude: [Technical Spec]
  - How: Use sci_tercen_client with createServiceFactoryForWebApp()
  - Repos: sci_tercen_client, sci_http_client, sci_base
  - Risks: CORS errors if done manually
  - Pattern: ServiceFactory injection

Claude: [Implementation Plan]
  1. Auto-fetch sci_tercen_client repo
  2. Add dependency to pubspec.yaml
  3. Create ServiceFactory in main.dart
  4. Register with GetIt
  5. Test with localhost tokens
  6. Test in Tercen deployment

Claude: [Calls ExitPlanMode]
User: [Approves]
Claude: [Implements following plan]
```

### Example 2: Simple Typo Fix

```
User: "Fix typo in README.md: 'teh' should be 'the'"

✅ CORRECT:
Claude: [Just fixes it - trivial change]
```

## Benefits of Following Workflow

### Prevents Issues Like

**Issue #1**: WASM build workflow confusion
- **Prevented by**: Technical Spec would document build→commit→push cycle

**Issue #3**: CORS errors from manual HTTP
- **Prevented by**: Technical Spec would reference sci_tercen_client pattern

**Issue #4**: index.html base href breaking deployment
- **Prevented by**: Technical Spec would include Tercen-specific requirements

**Issue #7**: Hot reload expectations
- **Prevented by**: Implementation Plan would note stop/restart requirement

### Ensures

- User understands what will be built
- Correct technical approach chosen
- Critical requirements not missed
- Efficient implementation (no rework)
- Comprehensive testing strategy

## Integration with Skills

### Skill 0: Flutter Foundation

- Documents workflow as foundational process
- Emphasizes planning for testability

### Skill 1: Mock Implementation

- Product Spec: What UI are we mocking?
- Technical Spec: Which assets, what mock data structure?
- Implementation Plan: Step-by-step mock service creation

### Skill 2: Tercen Implementation

- Product Spec: What Tercen integration needed?
- Technical Spec: Which sci_tercen_client patterns, auth flow, URL parsing
- Implementation Plan: Mock→Real transition, Tercen testing
- **Auto-fetch repos DURING technical spec phase**

### Skill 3: PamGene

- Product Spec: What PamGene-specific features?
- Technical Spec: Filename parsing, TIFF conversion, grid layout
- Implementation Plan: Utility creation, service integration

## Pre-Implementation Checklist

Before any code:

- [ ] Plan Mode entered (if non-trivial)
- [ ] Product Specification written
- [ ] Technical Specification written
- [ ] Implementation Plan created
- [ ] User has approved plan via ExitPlanMode
- [ ] All required repos auto-fetched (Skill 2)
- [ ] Critical files identified and reviewed

After approval:

- [ ] TodoWrite tool used to track implementation
- [ ] Follow plan step-by-step
- [ ] Stop and restart (not hot reload) for testing
- [ ] Verify against success criteria

## Deviation Handling

If Claude detects workflow being skipped:

```
Claude: "⚠️ I'm about to skip planning and write code directly.

This task appears non-trivial because:
- It involves [multiple files / architecture decisions / API integration]
- It could impact [authentication / deployment / existing features]

The mandatory workflow requires:
1. Enter Plan Mode
2. Create specifications
3. Get your approval
4. Then implement

Should we follow the mandatory workflow? (Recommended)"
```

## Success Metrics

✅ Every feature goes through full workflow
✅ Zero "surprise" issues from skipped planning
✅ User understands what will be built before it's built
✅ Implementation matches approved plan
✅ Reduced rework and debugging time

## See Also

- [Issue #1: WASM Build](1-wasm-build.md)
- [Issue #3: CORS Errors](3-cors-errors.md)
- [Issue #4: index.html Line 17](4-index-html-line17.md)
- [Issue #7: Hot Reload Broken](7-hot-reload-broken.md)
- All Skills (workflow applies to all)
