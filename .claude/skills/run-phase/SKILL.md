---
name: run-phase
description: Orchestrate a complete build-review-fix cycle for a given phase. Invokes the builder agent, then the reviewer, and loops until the review passes or the user intervenes.
disable-model-invocation: true
argument-hint: "[phase-number] [path-to-spec-or-widget]"
---

Orchestrate a build-review-fix cycle for Phase $ARGUMENTS[0].

This pipeline is for **window/header JSON widgets only** (5 phases).

## Workflow

### Phase 1 (Spec)

1. Invoke the **spec-writer** agent with the user's input
   - Agent uses `phase-1-spec` skill
2. When the spec is written, invoke the **reviewer** agent for Phase 1 review
   - Reviewer uses `phase-1-review` skill
3. If review **PASSES** → notify the user the spec is ready
4. If review **FAILS** → pass the failure items back to the spec-writer agent to fix
5. After fixes, re-run the reviewer
6. Loop steps 3-5 until PASS or the user intervenes

### Phase 2 (Mock — HTML)

1. Invoke the **mock-builder** agent with the functional spec at $ARGUMENTS[1]
   - Agent uses `phase-2-mock` skill (produces HTML wireframe, styled rendering, gap evaluation)
   - Output goes to `widgets/{name}/_mock/`
2. When the mock is complete, invoke the **reviewer** agent for Phase 2 review
   - Reviewer uses `phase-2-review` skill
3. If review **PASSES** → notify the user the HTML mock is ready
4. If review **FAILS** → pass the failure items back to the mock-builder agent to fix
5. After fixes, re-run the reviewer
6. Loop steps 3-5 until PASS or the user intervenes

### Phase 3 (Primitives)

1. Read the gap report from Phase 2 (`widgets/{name}/_mock/gap-report.md`)
2. If no gaps are listed → skip to Phase 4
3. Otherwise: fill gaps per the `phase-3-primitives` skill
   - Create missing SDUI primitives in `/home/martin/tercen/sdui/`
   - Run `cd /home/martin/tercen/sdui && dart analyze` to verify
   - Regenerate theme export and style guide as needed
4. Confirm all gaps resolved before proceeding

### Phase 4 (Catalog)

1. Invoke the **catalog-integrator** agent with the HTML mock at $ARGUMENTS[1]
   - Agent uses `phase-4-catalog` skill
   - Performs gap analysis against SDUI primitives (should find no gaps after Phase 3)
   - Authors catalog.json template entry
2. When integration completes, invoke the **reviewer** agent for Phase 5 review
   - Reviewer uses `phase-5-review` skill with `checks-catalog.md` checklist
3. If review **PASSES** → validate catalog.json parses cleanly, then notify user
4. If review **FAILS** → pass the failure items back to the catalog-integrator agent to fix
5. After fixes, re-run the reviewer
6. Loop steps 3-5 until PASS or the user intervenes

### Phase 5 (Review)

Final review is already executed as part of the Phase 4 loop above (step 2).
No separate invocation needed.

## Rules

- Maximum 5 review-fix cycles per phase before stopping and asking the user for guidance
- Each review-fix cycle must make progress — if the same issues persist after 2 cycles, stop and ask the user
- The builder agent does the work. The reviewer agent checks it. They do not negotiate — the reviewer's verdict is final
- All agents log issues to `_issues/session-log.md` throughout the process
- After a successful PASS, present the review report location to the user: `_local/review-{phase}.md`
