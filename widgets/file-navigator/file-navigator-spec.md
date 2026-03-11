# File Navigator — Functional Specification

**Version:** 1.0 Review Draft
**Date:** 2026-03-10
**Window:** 1 (File/Folder Navigator)
**App Type:** skeleton-window (Feature Window for Tercen Frame)
**Status:** Ready for review

---

## 1. Purpose

The File Navigator is the primary spatial orientation tool in the Tercen LLM platform. It presents the full hierarchy from teams down to individual files within projects. It is deliberately thin — it is NOT a file management tool.

The navigator exists for **three user actions**:

1. **Upload** — add data or files to a project
2. **Set focus** — single-click a project, folder, or file to tell the LLM what you are looking at
3. **Open** — double-click a file, data set, or workflow to view it in another window

All other operations (create, rename, move, delete, git push/pull) are performed by the **LLM via Chat**. Team and access management is handled by a separate **Team Widget**, triggered from the navigator via the EventBus.

---

## 2. Context — Where This Fits

### 2.1 Product context

The Tercen LLM platform has eight feature windows:

| # | Window | Role |
|---|--------|------|
| 0 | Home Page | Entry point and project navigation |
| **1** | **File Navigator** | **This spec — browse hierarchy, upload, set focus, open viewers** |
| 2 | Chat | Primary LLM interaction surface |
| 3 | Workflow Viewer | Pipeline visualisation and task management |
| 4 | Document Viewer/Editor | Markdown, SVG, reports |
| 5 | Data Viewer/Annotator | Tercen data tables |
| 6 | Visualisation Viewer/Annotator | Plots and images with markup |
| 7 | Audit Trail | Logs and history |

### 2.2 Three user types

| User | Relationship with the navigator |
|------|---------------------------------|
| **Scientist** | Primary user. Uploads data, clicks files to focus the LLM, opens viewers. Does not manage files directly — asks the LLM. |
| **Bioinformatician** | Publishes operators via GitHub. Uses the navigator to inspect projects. May use the filter to find specific workflows. |
| **Auditor** | Uses the navigator to locate projects and files for review. Primarily reads, does not upload or modify. |

---

## 3. Architecture — skeleton-window Conformance

This window conforms to the **skeleton-window** pattern from `tercen-flutter-skills/skeleton-window`.

### 3.1 App type

**Type 1 Feature Window** — rendered inside the Tercen Frame. The Frame provides tabs above this window. The navigator communicates with the Frame and other windows exclusively via the **EventBus**.

### 3.2 Project structure

```text
lib/
├── main.dart                           (entry point — rename class only)
├── core/
│   ├── theme/                          (DO NOT MODIFY — all design tokens)
│   │   ├── app_colors.dart
│   │   ├── app_colors_dark.dart
│   │   ├── app_spacing.dart
│   │   ├── app_text_styles.dart
│   │   ├── app_line_weights.dart
│   │   └── app_theme.dart
│   ├── constants/
│   │   └── window_constants.dart
│   ├── widgets/
│   └── utils/
│       └── context_detector.dart
├── domain/
│   ├── services/
│   │   ├── navigator_service.dart      (abstract)
│   │   └── event_bus_service.dart      (abstract)
│   └── models/
│       ├── tree_node.dart              (base class)
│       ├── team_node.dart
│       ├── project_node.dart
│       ├── folder_node.dart
│       ├── file_node.dart
│       ├── dataset_node.dart
│       └── workflow_node.dart
├── implementations/
│   └── services/
│       ├── mock_navigator_service.dart
│       ├── tercen_navigator_service.dart
│       ├── mock_event_bus_service.dart
│       └── tercen_event_bus_service.dart
├── di/
│   └── service_locator.dart            (DO NOT MODIFY — GetIt pattern)
└── presentation/
    ├── providers/
    │   ├── theme_provider.dart         (DO NOT MODIFY)
    │   ├── window_state_provider.dart
    │   └── tree_state_provider.dart
    ├── screens/
    │   └── navigator_screen.dart
    └── widgets/
        ├── toolbar/
        │   └── navigator_toolbar.dart
        └── tree/
            ├── tree_view.dart
            ├── team_node_tile.dart
            ├── project_node_tile.dart
            ├── folder_node_tile.dart
            ├── file_node_tile.dart
            ├── dataset_node_tile.dart
            └── workflow_node_tile.dart
```

### 3.3 Four body states

The window MUST implement all four body states per the skeleton-window pattern:

| State | When | Display |
|-------|------|---------|
| **Loading** | Fetching teams/projects from Tercen | Centred spinner + "Loading projects..." |
| **Empty** | User has no teams or projects | Centred icon + "No projects yet" + "Ask the AI to create a project" button |
| **Active** | Data loaded | Toolbar + Tree View |
| **Error** | Tercen connection failed | Centred error icon + message + "Retry" button |

### 3.4 Layout

Toolbar (48px fixed) + Body (flex). No left panel — this IS the navigator. No top bar — rendered inside Frame tabs. No preview panel — the Frame handles preview via EventBus events.

```text
┌──────────────────────────────────┐
│ Toolbar (48px)                   │
├──────────────────────────────────┤
│                                  │
│ Tree View (flex, scrollable)     │
│                                  │
└──────────────────────────────────┘
```

### 3.5 State management

Provider pattern with one-way data flow per skeleton-window rules:

```text
User interaction → Provider.setXxx() → notifyListeners() → Consumer rebuilds
```

**TreeStateProvider** fields:

| Field | Type | Purpose |
|-------|------|---------|
| `teams` | `List<TeamNode>` | Full tree data |
| `expandedNodeIds` | `Set<String>` | Which nodes are expanded |
| `selectedNodeId` | `String?` | Currently focused node |
| `filterText` | `String` | Text search string |
| `filterType` | `TercenDocType?` | Type filter (null = All) |
| `uploadingToProjectId` | `String?` | Upload in progress target |

**WindowStateProvider** fields:

| Field | Type | Purpose |
|-------|------|---------|
| `state` | `WindowState` | loading / empty / active / error |
| `errorMessage` | `String?` | Error detail text |

### 3.6 Mock/real switching

```dart
// Phase 2: Mock data for development
const useMocks = bool.fromEnvironment('USE_MOCKS', defaultValue: true);
setupServiceLocator(useMocks: true);

// Phase 3: Real Tercen integration
setupServiceLocator(useMocks: false, factory: factory, taskId: taskId);
```

### 3.7 Theming rules

- All UI chrome is theme-aware (light + dark)
- Use only design tokens: `AppColors.*`, `AppColorsDark.*`, `AppSpacing.*`, `AppTextStyles.*`, `AppLineWeights.*`
- No hardcoded colours, font sizes, spacing, or stroke widths
- Dark mode detection:

```dart
final isDark = context.watch<ThemeProvider>().isDarkMode;
final color = isDark ? AppColorsDark.textSecondary : AppColors.textSecondary;
```

### 3.8 Window identity

| Property | Value |
|----------|-------|
| Tab label | "Navigator" |
| Tab icon | 8x8px coloured square (suggest `AppColors.primary`) |

---

## 4. Hierarchy Model

### 4.1 Tree structure

```text
Personal (user's own team — auto-expanded on load)
├── Project A/
│   ├── omip69_1k_donor.zip           (File)
│   ├── Sample_annotation.csv          (Data Set)
│   ├── Flow Immunophenotyping         (Workflow)
│   └── README.md                      (File)
├── Project B/
│   └── ...
TeamAlpha (collapsed on load — click to expand)
├── Shared Project 1/
│   └── ...
└── Shared Project 2/
    └── ...
TeamBeta (collapsed on load)
└── ...
```

### 4.2 Hierarchy rules

| Rule | Detail |
|------|--------|
| **Personal team first** | The user's own team is always listed first and auto-expanded to show its project list |
| **Other teams collapsed** | All other teams are listed below, collapsed. Click to expand. |
| **Projects collapsed** | Projects within a team are collapsed. Click to expand. |
| **Flat project contents** | Within a project, contents are a flat list of Tercen documents (Files, Data Sets, Workflows), subject to the toolbar filter |
| **Folders shown** | `FolderDocument` items are shown as expandable nodes within a project |
| **Computed tables hidden** | `ComputedTableSchema` and `CubeQueryTableSchema` are NOT shown — accessed via Workflow Viewer (Window 3) |
| **LLM can navigate** | The LLM can open the tree to any node via EventBus `navigateTo` event |

### 4.3 Tercen document types shown

These are the three user-facing document types. They map directly to Tercen's internal `subKind` values:

| User label | Tercen `subKind` | What it is |
|------------|-----------------|------------|
| **File** | `FileDocument` | Raw files: FCS, ZIP, CSV, markdown, images, code |
| **Data Set** | `TableSchema` | Structured data tables imported into Tercen |
| **Workflow** | `Workflow` | Analysis pipelines |

---

## 5. Operations Matrix

### 5.1 Local actions (the navigator handles these internally)

| Action | Team | Project | Folder | File / Data Set / Workflow |
|--------|------|---------|--------|---------------------------|
| **Expand / Collapse** | Yes (click chevron) | Yes (click chevron) | Yes (click chevron) | — (leaf nodes) |
| **Upload** | — | Yes | Yes | — |
| **Filter (type + text)** | Applies at all levels | Applies at all levels | Applies at all levels | Applies at all levels |
| **Single-click (set focus)** | — | Yes | Yes | Yes |

### 5.2 Emitted intents (EventBus — Frame orchestrates the response)

The navigator does not open windows, download files, or manage teams directly. It emits intents and the Frame acts on them.

| Intent | Team | Project | Folder | File / Data Set / Workflow |
|--------|------|---------|--------|---------------------------|
| `focusChanged` | — | Single-click | Single-click | Single-click |
| `openViewer` | — | — | — | Double-click |
| `openTeamWidget` | Toolbar button | — | — | — |
| `downloadFile` | — | — | — | Toolbar button |

---

## 6. Toolbar

48px fixed height. Follows the skeleton-window toolbar pattern: left-aligned icon buttons.

### 6.1 Buttons

| Button | Icon type | Active when | Action |
|--------|-----------|-------------|--------|
| **Upload** | Primary accent | Project or folder selected | Opens file picker / activates drag-drop |
| **Download** | Standard | File / Data Set selected | Emits `downloadFile` on EventBus |
| **Refresh** | Standard | Always | Re-fetches tree data from Tercen |
| **Team** | Standard | Team selected | Emits `openTeamWidget` on EventBus |
| **Type filter** | Dropdown button | Always | Filters tree by Tercen document type |
| **Text search** | Text input | Always | Filters tree by name (case-insensitive) |

### 6.2 Type filter dropdown

The type filter is a dropdown button. Each option has hover text explaining what it filters to:

| Option | Hover text | Shows |
|--------|-----------|-------|
| **All** | "Show all document types" | Everything in the tree |
| **File** | "Show files only (FCS, ZIP, CSV, images, etc.)" | `FileDocument` items |
| **Data Set** | "Show data sets only (imported data tables)" | `TableSchema` items |
| **Workflow** | "Show workflows only (analysis pipelines)" | `Workflow` items |

The type filter and text search work together. Type filter narrows by `subKind`, text search narrows further by name. Both are client-side filters applied to the already-loaded tree data.

### 6.3 Toolbar styling

| Property | Token |
|----------|-------|
| Height | `AppSpacing.headerHeight` (48px) |
| Button spacing | `AppSpacing.sm` (8px) |
| Button group dividers | `AppLineWeights.subtle` (1.0px) |
| Text search border | `AppColors.neutral300` |
| Text search font | `AppTextStyles.body` |
| Upload button background | `AppColors.primary` |
| Inactive buttons | `AppColors.textDisabled` |

---

## 7. Tree View

### 7.1 Interactions

| Gesture | On branch node (Team, Project, Folder) | On leaf node (File, Data Set, Workflow) |
|---------|----------------------------------------|----------------------------------------|
| **Single-click** | Set focus (emit `focusChanged`) | Set focus (emit `focusChanged`) |
| **Click chevron** | Toggle expand/collapse | — (no chevron) |
| **Double-click** | — | Open viewer (emit `openViewer`) |
| **Drag to Chat** | — | Emit `focusChanged` + Chat message |
| **Arrow keys** | Navigate between rows | Navigate between rows |
| **Enter** | Toggle expand/collapse | Emit `openViewer` |

Note: single-click on a Team node does NOT emit `focusChanged` — it only expands/collapses.

### 7.2 Node tile layout

Each row in the tree follows this layout:

```text
[indent] [chevron] [type icon] [name] [status badges] [inline info]
```

### 7.3 Node tile styling

| Property | Token |
|----------|-------|
| Row height | 28px |
| Indentation per level | `AppSpacing.lg` (24px) |
| Chevron size | 16x16px |
| Chevron colour | `AppColors.textTertiary` |
| Type icon size | 16x16px |
| Name font | `AppTextStyles.body` |
| Name colour | `AppColors.textPrimary` |
| Hover background | `AppColors.neutral100` (light) / `AppColorsDark.neutral800` (dark) |
| Selected background | `AppColors.primary` at 10% opacity |
| Selected left border | 2px, `AppColors.primary` |

### 7.4 Type icons

| Icon | Node type | Colour |
|------|-----------|--------|
| `Icons.people` | Team | `AppColors.primary` |
| `Icons.folder` | Project | `AppColors.warning` |
| `Icons.folder_open` | Folder (`FolderDocument`) | `AppColors.textTertiary` |
| `Icons.insert_drive_file` | File — generic | `AppColors.textSecondary` |
| `Icons.science` | File — FCS | `AppColors.success` |
| `Icons.archive` | File — ZIP | `AppColors.textSecondary` |
| `Icons.description` | File — Markdown/text | `AppColors.textSecondary` |
| `Icons.image` | File — PNG/SVG/JPEG | `AppColors.info` |
| `Icons.table_chart` | Data Set (`TableSchema`) | `AppColors.info` |
| `Icons.account_tree` | Workflow | `AppColors.primary` |

### 7.5 Status indicators

Displayed inline after the node name:

| Indicator | Where | Display | Tokens |
|-----------|-------|---------|--------|
| Workflow status | Workflow nodes | 8x8px coloured circle | idle: `neutral400`, running: `info`, complete: `success`, error: `error` |
| Git version | Project nodes (git-backed) | Text in rounded chip | `AppTextStyles.labelSmall`, `AppColors.neutral200` background |
| Git status | Project nodes (git-backed) | 8x8px dot | clean: `success`, modified: `warning` |
| GitHub link | Project nodes (git-backed) | `Icons.open_in_new` (12px) | `AppColors.textTertiary`, opens browser |
| Member count | Team nodes | Text in parentheses | `AppTextStyles.labelSmall`, `AppColors.textMuted` |
| Public badge | Project nodes | `Icons.public` (12px) | `AppColors.info` |

---

## 8. Upload

| Aspect | Detail |
|--------|--------|
| **Trigger** | Toolbar Upload button (when project or folder selected) or drag-and-drop from desktop |
| **Valid targets** | Project nodes, folder nodes |
| **Drop feedback** | Highlight target row: `AppColors.primary` at 15% opacity, dashed border `AppLineWeights.standard` |
| **Progress** | Inline progress bar below target node, `AppColors.primary` |
| **File type detection** | Automatic on upload (FCS, CSV, ZIP detected by extension/content) |
| **On completion** | Emits `contentChanged` on EventBus; tree refreshes to show the new file |

---

## 9. Focus (Chat Integration)

Single-click on a project, folder, or file/dataset/workflow node:

1. Updates `TreeStateProvider.selectedNodeId`
2. Emits `focusChanged(nodeId, nodeType, nodeName, nodePath)` on EventBus
3. The Chat window (Window 2) reads this event and updates its **Focus field**
4. The LLM receives the focus context automatically with every subsequent message

Drag-and-drop of a tree node onto the Chat window also emits `focusChanged` and triggers a Chat message.

Single-click on a Team node does NOT set focus — it only expands/collapses.

---

## 10. Open Viewer

Double-click on a leaf node emits `openViewer(nodeId, nodeType)` on EventBus. The **Frame orchestrator** decides which window to open. The navigator does not know or care about window routing.

Suggested Frame routing (informational — not part of this spec):

| Node type | Suggested window |
|-----------|-----------------|
| Workflow | Workflow Viewer (Window 3) |
| File — Markdown, text | Document Viewer/Editor (Window 4) |
| Data Set | Data Viewer/Annotator (Window 5) |
| File — PNG, SVG, image | Visualisation Viewer/Annotator (Window 6) |
| File — FCS, ZIP | Data Viewer with import preview (Window 5) |

---

## 11. Team Widget Trigger

When a team node is selected and the user clicks the **Team** button in the toolbar:

- Emits `openTeamWidget(teamId)` on EventBus
- The Frame opens the Team management widget (separate component, not part of this spec)
- The Team widget handles: member list, add/remove members, public/private toggle for team and project

---

## 12. Git Information

For projects backed by a git repository, status is displayed inline on the project node (see Section 7.5). No git actions (push, pull, branch) are available in the navigator — these are performed by the LLM via Chat.

---

## 13. EventBus Communication

### 13.1 Events the navigator emits

| Event | Payload | Triggered by |
|-------|---------|-------------|
| `focusChanged` | `nodeId`, `nodeType`, `nodeName`, `nodePath` | Single-click on project, folder, or file/dataset/workflow |
| `openViewer` | `nodeId`, `nodeType` | Double-click on file/dataset/workflow |
| `openTeamWidget` | `teamId` | Toolbar Team button (when team selected) |
| `downloadFile` | `fileId` | Toolbar Download button (when file selected) |
| `contentChanged` | — | After upload completes |

### 13.2 Events the navigator listens to

| Event | Payload | Action |
|-------|---------|--------|
| `navigateTo` | `nodeId` or `path` | Expand tree to the specified node and highlight it |
| `refreshTree` | — | Re-fetch all data from Tercen and rebuild the tree |

### 13.3 Window interaction map

| Window | Direction | Event |
|--------|-----------|-------|
| Home Page (0) | Home → Navigator | `navigateTo` — open tree to a project |
| Chat (2) | Navigator → Chat | `focusChanged` — set Chat Focus field |
| Chat (2) | Chat → Navigator | `navigateTo` — LLM opens tree to a node |
| Frame | Navigator → Frame | `openViewer` — Frame routes to appropriate window |
| Frame | Navigator → Frame | `openTeamWidget` — Frame opens Team Widget |
| Frame | Navigator → Frame | `downloadFile` — Frame handles download |
| Audit Trail (7) | No direct interaction | — |

---

## 14. Domain Models

### 14.1 TreeNode (base class)

```dart
abstract class TreeNode {
  String get id;
  String get name;
  TreeNodeType get nodeType;  // team, project, folder, file, dataset, workflow
  String? get parentId;
  List<TreeNode> get children;
  bool get isLeaf;
}
```

### 14.2 TercenDocType (filter enum)

```dart
enum TercenDocType {
  all,        // No filter — show everything
  file,       // FileDocument
  dataset,    // TableSchema
  workflow,   // Workflow
}
```

### 14.3 Concrete node types

**TeamNode**

```dart
class TeamNode extends TreeNode {
  final String id;
  final String name;
  final int memberCount;
  final bool isPublic;
  final bool isPersonal;          // user's own team — listed first, auto-expanded
  final List<ProjectNode> projects;
}
```

**ProjectNode**

```dart
class ProjectNode extends TreeNode {
  final String id;
  final String name;
  final String? description;
  final bool isPublic;
  final String? gitUrl;            // GitHub repo URL (null if not git-backed)
  final String? gitVersion;        // version tag
  final GitStatus? gitStatus;      // clean / modified
  final List<TreeNode> children;   // flat list of files, datasets, workflows, folders
}
```

**FolderNode**

```dart
class FolderNode extends TreeNode {
  final String id;
  final String name;
  final List<TreeNode> children;
}
```

**FileNode**

```dart
class FileNode extends TreeNode {
  final String id;
  final String name;
  final FileType fileType;         // fcs, zip, csv, markdown, image, generic
  final int? sizeBytes;
  final DateTime? createdDate;
  final DateTime? lastModifiedDate;
}
```

**DatasetNode**

```dart
class DatasetNode extends TreeNode {
  final String id;
  final String name;
  final String? description;
  final int? rowCount;
  final int? columnCount;
  final DateTime? createdDate;
}
```

**WorkflowNode**

```dart
class WorkflowNode extends TreeNode {
  final String id;
  final String name;
  final int stepCount;
  final WorkflowStatus status;    // idle, running, complete, error
  final DateTime? lastRunDate;
}
```

---

## 15. Service Interfaces

### 15.1 NavigatorService

```dart
abstract class NavigatorService {
  Future<List<TeamNode>> fetchTeams();
  Future<List<TreeNode>> fetchProjectContents(String projectId);
  Future<void> uploadFile(String projectId, String? folderId, File file);
}
```

### 15.2 EventBusService

```dart
abstract class EventBusService {
  // Emit
  void emitFocusChanged(String nodeId, TreeNodeType nodeType, String nodeName, String nodePath);
  void emitOpenViewer(String nodeId, TreeNodeType nodeType);
  void emitOpenTeamWidget(String teamId);
  void emitDownloadFile(String fileId);
  void emitContentChanged();

  // Listen
  Stream<NavigateToEvent> get onNavigateTo;
  Stream<RefreshEvent> get onRefreshTree;
}
```

---

## 16. What the Navigator Does NOT Do

| Action | Where it is handled |
|--------|-------------------|
| Create projects, workflows, documents, folders | LLM via Chat (Window 2) |
| Rename, move, delete files | LLM via Chat (Window 2) |
| Browse the operator library | LLM internally (not user-facing) |
| View computed/intermediate tables | Workflow Viewer (Window 3) |
| View computation logs | Workflow Viewer (Window 3) |
| Manage knowledge base / RAG sources | Separate component (TBD) |
| Git push, pull, branch operations | LLM via Chat (Window 2) |
| Edit file contents | Document Editor (Window 4) / Data Viewer (Window 5) |
| Preview or inspect selected items | Frame orchestrator |
| Team management (members, public/private) | Team Widget (via `openTeamWidget` event) |
| Notifications | Out of scope for rev 1 |

---

## 17. Wireframe

```text
┌──────────────────────────────────────────────┐
│ [⬆ Upload] [⬇ Download] [↻] [👥]  [▾ All] 🔍 │  ← Toolbar (48px)
├──────────────────────────────────────────────┤
│                                              │
│ ▼  👤  Personal                              │  ← Auto-expanded
│    ▶  Project1                               │
│    ▼  immuno                                 │  ← User expanded this
│       📄  README.md                          │     File
│       🧪  omip69_1k_donor.zip               │     File (FCS)
│       📊  Sample_annotation.csv              │     Data Set
│       📊  OMIP-069 - Channel Descriptions    │     Data Set
│       ⚙  Flow Immuno...  🟢                 │     Workflow (complete)
│    ▶  flow_preprocessing   v2.3  ✓           │  ← Git version + clean
│                                              │
│ ▶  👥  MartinLibrary  (3)                    │  ← Collapsed, 3 members
│ ▶  👥  MyNewTeam  (1)                        │
│ ▶  👥  Team10Dec2025  (2)                    │
│                                              │
└──────────────────────────────────────────────┘

Toolbar buttons:
  ⬆ Upload     Active when project or folder is selected
  ⬇ Download   Active when file or data set is selected
  ↻ Refresh    Always active
  👥 Team      Active when team is selected
  ▾ All        Type filter dropdown (All / File / Data Set / Workflow)
  🔍           Text search input (filters by name)
```

---

## 18. LLM Integration

The LLM interacts with the navigator indirectly through the EventBus:

1. **Reads focus** — when the user single-clicks in the tree, `focusChanged` is broadcast. The LLM receives this as context with every subsequent Chat message.
2. **Navigates the tree** — after creating or modifying a file, the LLM emits `navigateTo` to expand the tree and highlight the result.
3. **Triggers refresh** — after file admin operations (create, rename, move, delete), the LLM emits `refreshTree` so the navigator reloads.
4. **Does not use the navigator directly** — the LLM uses Tercen MCP tools to create projects, workflows, and files. The navigator simply reflects the current state.

---

## 19. Decision Log

Decisions made during the design process, for reference:

| # | Decision | Rationale |
|---|----------|-----------|
| 1 | Navigator covers the full hierarchy (teams → projects → files), not just project-internal | Teams and projects are just folders in the structure. Users need one place to navigate everything. |
| 2 | Only three direct user actions: upload, set focus, open viewer | Scientists should not need to learn file management. The LLM handles create/rename/move/delete via Chat. |
| 3 | No preview panel in the navigator | Selection and preview are the Frame's responsibility. The navigator emits events; the Frame decides what to show. |
| 4 | Team management handled by a separate Team Widget | All team features (members, public/private) are triggered by an EventBus signal, keeping the navigator thin. |
| 5 | Set Public is project-level only (not team-level) | Simplifies access model. Teams own projects; public/private is a project attribute. |
| 6 | No virtual folder grouping (Data/, Workflows/, Documents/) | Project contents are shown as a flat list, filtered by the type dropdown. Simpler and more aligned with Tercen's actual data model. |
| 7 | Three filter types: File, Data Set, Workflow | Maps directly to Tercen's `subKind` values: `FileDocument`, `TableSchema`, `Workflow`. |
| 8 | Single-click = set focus, double-click = open viewer | Two distinct events. Focus tells the LLM what you are looking at. Open tells the Frame to launch a window. |
| 9 | Single-click on Team does NOT set focus | Team click only expands/collapses. Focus is meaningful at project, folder, and file level. |
| 10 | Expand/collapse is handled by tree chevrons, not a toolbar button | No "Collapse All" button needed — the tree's own chevrons are sufficient. |
| 11 | Notifications are out of scope for rev 1 | Will be addressed in a future revision with a notification widget on the EventBus. |
| 12 | Computed tables (ComputedTableSchema, CubeQueryTableSchema) are hidden | These are intermediate computation artefacts. They are accessed via the Workflow Viewer, not the file tree. |
| 13 | Git actions (push, pull) are performed by the LLM | The navigator shows git status (version, clean/modified, GitHub link) but does not expose git operations. |
| 14 | The navigator conforms to skeleton-window from tercen-flutter-skills | Ensures consistency with all other Tercen windows: same theming, state management, DI, and mock/real switching patterns. |

---

## 20. Open Questions

| # | Question | Impact |
|---|----------|--------|
| 1 | **Chat sessions in the tree** — Should chat sessions appear as a document type with their own filter category and node type? | Adds a 4th filter option and a ChatNode model. |
| 2 | **Multi-project focus** — Can the Chat focus on items from multiple projects simultaneously, or is focus always single-item? | Affects `focusChanged` event payload and Chat Focus field design. |
| 3 | **Offline/loading states** — When the Tercen server is slow, show loading per-node (lazy load on expand) or global loading? | Affects UX for large team structures with many projects. |
| 4 | **Tree depth** — Should deeply nested folders be flattened or capped at a maximum depth? | Affects rendering for projects with complex folder structures. |
| 5 | **Folder filter behaviour** — When a type filter is active (e.g. "Workflow"), should folders still be shown if they contain matching items? | Affects filter logic — may need to walk folder contents to determine visibility. |
