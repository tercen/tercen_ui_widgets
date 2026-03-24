---
name: run-phase
description: Orchestrate a complete build-review-fix cycle for a given phase. Invokes the builder agent, then the reviewer, and loops until the review passes or the user intervenes.
disable-model-invocation: true
argument-hint: "[phase-number] [path-to-spec-or-app]"
---

Orchestrate a build-review-fix cycle for Phase $ARGUMENTS[0].

## Kind Detection

Before invoking any agent, detect the widget kind:

1. Read `skeleton.yaml` in the project root. The `kind` field determines the widget kind.
2. If no `skeleton.yaml`, fall back to file-presence detection:
   - `lib/presentation/widgets/header_panel.dart` or `lib/presentation/widgets/content_panel/` → **runner**
   - `lib/presentation/widgets/window_shell.dart` → **window**
   - Otherwise → **panel**
3. For Phase 1 (no project yet): ask the user which widget kind they want.

## Workflow

### Phase 1 (Functional Spec)

1. Invoke the **spec-writer** agent with the user's input
   - Agent uses `phase-1-functional-spec` skill (dispatches by kind internally)
2. When the spec is written, invoke the **reviewer** agent for Phase 1 review
   - Reviewer uses `phase-1-review` skill (dispatches by kind internally)
3. If review **PASSES** → notify the user the spec is ready
4. If review **FAILS** → pass the failure items back to the spec-writer agent to fix
5. After fixes, re-run the reviewer
6. Loop steps 3–5 until PASS or the user intervenes

### Phase 2 (Mock Build)

1. Invoke the **mock-builder** agent with the functional spec at $ARGUMENTS[1]
   - Agent uses `phase-2-mock-build` skill (dispatches by kind internally)
2. When the build completes, invoke the **reviewer** agent for Phase 2 review
   - Reviewer uses `phase-2-review` skill (dispatches by kind internally)
3. If review **PASSES** → run `flutter build web --wasm` to verify, then notify user
4. If review **FAILS** → pass the failure items back to the mock-builder agent to fix
5. After fixes, re-run the reviewer
6. Loop steps 3–5 until PASS or the user intervenes

### Phase 3 (Tercen Integration)

**Route by widget kind:**

- **panel** or **runner** → use the **integrator** agent (standalone Flutter app with real Tercen services)
- **header** or **window** → use the **catalog-integrator** agent (catalog.json template with SDUI primitives)

#### Panel / Runner (standard integration)

1. Invoke the **integrator** agent with the mock widget at $ARGUMENTS[1]
2. When integration completes, invoke the **reviewer** agent for Phase 3 review
3. If review **PASSES** → run `flutter build web --wasm` to verify, then notify user
4. If review **FAILS** → pass the failure items back to the integrator agent to fix
5. After fixes, re-run the reviewer
6. Loop steps 3–5 until PASS or the user intervenes

*Supports panel widgets (Flows A-D) and runner widgets (Flow E: workflow execution).*

#### Header / Window (catalog integration)

1. Invoke the **catalog-integrator** agent with the mock widget at $ARGUMENTS[1]
   - Agent uses `phase-3-catalog-integration` skill (dispatches by kind: header or window)
   - Performs gap analysis against SDUI primitives
   - Creates missing primitives in the sdui package if needed
   - Authors catalog.json template entry
2. When integration completes, invoke the **reviewer** agent for Phase 3 review
   - Reviewer uses `phase-3-review` skill with `checks-catalog.md` checklist
3. If review **PASSES** → validate catalog.json parses cleanly, then notify user
4. If review **FAILS** → pass the failure items back to the catalog-integrator agent to fix
5. After fixes, re-run the reviewer
6. Loop steps 3–5 until PASS or the user intervenes

*Output is a catalog.json entry, not a standalone Flutter app. No `flutter build` step needed.*

## Rules

- Maximum 5 review-fix cycles before stopping and asking the user for guidance
- Each review-fix cycle must make progress — if the same issues persist after 2 cycles, stop and ask the user
- The builder agent does the work. The reviewer agent checks it. They do not negotiate — the reviewer's verdict is final
- All agents log issues to `_issues/session-log.md` throughout the process
- After a successful PASS, present the review report location to the user: `_local/review-{phase}.md`
