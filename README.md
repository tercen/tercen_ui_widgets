# Tercen Flutter Skills

Build Tercen Flutter web apps in 3 phases. Each phase is a separate Claude Code session loading one skill.

## Quick start

1. Clone this repo into your new app project
2. Start a Claude Code session
3. Tell Claude which phase you're in and point it to the skill file

## Phases

| Phase | What happens | Skill to load | Input | Output |
| ----- | ------------ | ------------- | ----- | ------ |
| 1 | Write functional spec | `skills/phase-1-functional-spec.md` | User requirements, screenshots, existing code | Functional spec markdown document |
| 2 | Build mock app | `skills/phase-2-mock-build.md` | Functional spec + `skeleton/` | Running Flutter app with mock data |
| 3 | Connect to Tercen | `skills/phase-3-tercen-integration.md` | Working mock app + taskId | Deployed app in Tercen |

## How to use

### Phase 1: Functional spec

Start a new Claude Code session. Tell Claude:

> Read `skills/phase-1-functional-spec.md`. I want to build [describe your app]. Here is [screenshot / Shiny code / description].

Claude will work through discovery questions and produce a standardised functional spec document.

### Phase 2: Mock build

Start a new Claude Code session. Tell Claude:

> Read `skills/phase-2-mock-build.md`. Here is the functional spec: [path to spec]. The skeleton is in `skeleton/`.

Claude will copy the skeleton, replace placeholders using the spec, and produce a working mock app. Verify it runs with `flutter run -d chrome`.

### Phase 3: Tercen integration

Start a new Claude Code session. Tell Claude:

> Read `skills/phase-3-tercen-integration.md`. The mock app is at [path]. My taskId is [id].

Claude will replace mock services with real Tercen data services, build, and deploy.

## Rules

- **One skill per session.** Do not load multiple skills.
- **Phase 1 output bridges to Phase 2.** The functional spec markdown document.
- **Phase 2 output bridges to Phase 3.** The working mock app.
- **Do not modify the skeleton structure.** Copy it, rename it, replace placeholders. Do not restructure the app shell, left panel, or theme system.

## What's in the skeleton

`skeleton/` is a runnable Flutter web app (Type 1: visualization). It has:

- App shell with conditional top bar
- Left panel with collapse, resize, sections, header/footer
- Light/dark theme with Tercen brand colours
- Provider state management with wiring examples
- GetIt dependency injection with mock/real switching
- INFO section with GitHub link
- Deployment files (operator.json, index.html, .gitignore)

Run it: `cd skeleton && flutter run -d chrome`

## App types

| Type | Data flow | Status |
| ---- | --------- | ------ |
| 1: Visualization | Tercen -> App -> Screen | Supported (3 deployed apps) |
| 2: Interactive | Tercen -> App -> Screen -> Write back | Phase 3 skill covers read; write-back TBD |
| 3: Workflow manager | Multi-step orchestration | Not yet attempted |

## Updating skills

Skills are **read-only during app builds**. Claude must never modify skill files while building an app.

### Feedback process

1. **During an app build**: If Claude encounters a skill gap or error, it notes it in the app's `_local/skill-feedback.md` — what it expected, what happened, what it did instead
2. **After the build**: Copy the feedback file into this repo's `_feedback/` directory
3. **Dedicated session**: Open a Claude Code session in this repo and say "review feedback and update skills". Claude reads the feedback, proposes changes, you approve

### What goes in skill-feedback.md

```markdown
## [Date] - [App name] - Phase [N]

**Skill gap**: [what the skill didn't cover]
**What happened**: [what Claude encountered]
**Workaround used**: [what Claude did instead]
**Suggested fix**: [how the skill should change]
```

## Style guide

The Tercen style guide is baked into the skeleton. Do not clone or read it during app builds. It is maintained separately at <https://github.com/tercen/tercen-style>.
