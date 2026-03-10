# Window Widget — Design Summary

> Reference for window widget skills. This document will expand as the window design matures.

---

## What Is a Window Widget?

A **feature window** that runs inside the Tercen UI Orchestrator frame. It provides:

1. Contextual information for both user and LLM during chat interactions
2. Interactive controls that instruct the LLM to perform Tercen functions
3. A display layer for Tercen data, navigation, and workflow context

Unlike panel and runner widgets, window widgets do not operate standalone — they are embedded within the orchestrator and communicate via message passing.

---

## Layout

Single-panel window with toolbar, body, and body state management.

```
┌─ Window Toolbar ────────────────────────────────┐
│  [Tab icon] [Title]              [Actions]       │
├─────────────────────────────────────────────────┤
│                                                  │
│  Window Body                                     │
│  (state-driven: loading / empty / active / error)│
│                                                  │
└─────────────────────────────────────────────────┘
```

---

## Skeleton Reference

Skeleton at `skeletons/window/`. Key files:

| File | Purpose |
|------|---------|
| `lib/presentation/widgets/window_shell.dart` | Window frame and layout |
| `lib/presentation/widgets/window_toolbar.dart` | Toolbar with tabs and actions |
| `lib/presentation/widgets/window_body.dart` | Body state switching |
| `lib/presentation/widgets/body_states/*.dart` | Loading, empty, active, error states |
| `lib/domain/services/event_bus.dart` | Message passing with orchestrator |
| `lib/domain/models/window_identity.dart` | Window identity and configuration |
| `lib/domain/models/content_state.dart` | Content state management |

---

## Design Details

To be defined as the window widget matures. Key areas to document:

- Orchestrator communication protocol (postMessage events)
- LLM instruction interface
- Content type registry
- Navigation integration
- Theme synchronization with parent frame
