# Session Log

2026-03-11 [skill-gap] checks-window.md contains no window-specific checks ("will be added as the window widget design matures"), leaving EventBus contract completeness, identity/tab-colour assignment, four body states, toolbar definition, and hierarchy model coverage entirely unverified by the review skill for window kind specs.
## Session: 2026-03-11 — Phase 2
- [skill-gap] Window skeleton missing version_info.dart and operator.json — created from panel skeleton template
- [pattern] NavigatorProvider extends WindowStateProvider and is registered under both types so WindowBody can find it via context.watch<WindowStateProvider>()
- [workaround] HomeScreen builds custom toolbar inline (showToolbar:false on WindowShell) because spec requires dropdown + text search which exceed ToolbarAction icon-button model
- [workaround] Tree view widgets inlined in home_screen.dart rather than active_state.dart to avoid import chain issues with WindowStateProvider vs NavigatorProvider
- [fixed] D3: Removed extra theme toggle button from toolbar -- spec defines exactly 6 controls
- [fixed] D6: Added keyboard navigation (arrow up/down + Enter) via Focus+onKeyEvent on tree view
- [fixed] F1: Removed Map<String,dynamic> loadData() from DataService interface -- only domain types remain
- [fixed] H1: Commented out base href, updated title and apple-mobile-web-app-title to File Navigator
- [fixed] H2: Created .gitignore with !build/web/ to keep build artefacts tracked in git
- [fixed] Change 1: Removed Refresh toolbar button
- [fixed] Change 2: Replaced node icon/colour mapping per spec table
- [fixed] Change 3: Redesigned type filter as icon-based PopupMenuButton 32x32
- [fixed] Change 4: Upload button opens OS file picker via web.HTMLInputElement
- [fixed] Change 5: Simplified status indicators to project-only Public icon + GitHub chip
- [fixed] Change 6: Added mock-only FAB theme toggle with DEV label and reduced opacity
- [fixed] Change 7: Added inert mock tab strip with TabTypeIcon yellow square + Navigator label
## Session: 2026-03-11 — Phase 2 (continued)
- [fixed] GitHub icon: replaced Icons.code with FaIcon(FontAwesomeIcons.github) via font_awesome_flutter
- [fixed] Indicators inline: changed Expanded to Flexible on name Text so Public/GitHub chips sit after name
- [fixed] Project icon colour: changed from primary to neutral500/neutral400 grey
- [fixed] Reverted Project icon colour back to primary (previous change was incorrect)
- [fixed] Public icon colour changed from primary to neutral500/neutral400 grey
- [fixed] Reordered indicators: GitHub chip first, Public icon second
- [fixed] Added githubUrl + gitVersion to PCA Analysis project so both indicators display together
## Session: 2026-03-11 — Phase 2 (fresh rebuild)
- [pattern] Complete rebuild of file-navigator from updated window skeleton — deleted all previous files except spec and _local
- [workaround] Spec says Project icon should be Warning/amber colour, user override says use AppColors.primary — following user override
- [workaround] Spec section 7.4 has per-file-type icons (FCS=green, markdown=text). User override: ALL files use generic file icon in neutral700. Following user override.
- [workaround] Spec section 7.5 has workflow status dots, git status dots, member counts. User override: ONLY GitHub chip + public icon on project nodes. Following user override.
- [workaround] Spec has Refresh button in toolbar. User override: NO Refresh button. Following user override.
- [fixed] Change 1: All toolbar buttons (Upload, Download, Team) now use isPrimary=true; filter dropdown also uses primary accent styling
- [fixed] Change 2: Search field uses Flexible+ConstrainedBox(maxWidth:220), exact 36px height, isCollapsed+textAlignVertical.center for proper vertical centering
- [fixed] Change 3: Filter dropdown items are icon-only (no text labels) with tooltips; colours match tree node icon colours exactly
- [fixed] Change 4: Immunophenotyping project now has root-level items AND a "reports" folder with 3 child files; flow_preprocessing also has mixed hierarchy
- [fixed] Search icon changed from magnifyingGlass size 12 to size 14; clear icon from Icons.close to FaIcon(FontAwesomeIcons.xmark, size:12)
- [fixed] Search maxWidth changed from 220 to 440
- [fixed] Filter dropdown: popup constrained to 48-56px wide, items centred with padding:EdgeInsets.zero
- [fixed] Toolbar tooltips: Upload/Download/Teams/Filter
- [fixed] Text style: filter "All" and search placeholder both use AppTextStyles.body (14px w400) per design-tokens text-sm
- [fixed] Sort: _sortTree in NavigatorProvider — README.md first, then datasets, workflows, files, folders (all alpha within group)
- [fixed] Search icon alignment: prefixIcon and suffixIcon wrapped in SizedBox+Center for proper FaIcon centering within 36px height
- [fixed] Filter bug: branch nodes returned true from _nodeMatchesFilter when type filter active, bypassing child filtering. Now branches return false when typeFilter != all, forcing recursive pruning of non-matching leaves.
- [fixed] Click behaviour: all branch nodes (team/project/folder) now do both toggleExpanded + selectNode on single click
## Session: 2026-03-11 — Phase 1
- Writing workflow-viewer functional spec (window kind, sister to file-navigator)
- [pattern] Followed file-navigator spec structure (20 sections) adapted for flowchart widget: replaced tree hierarchy with step type matrix, tree view with layout algorithm, upload with execution control
- [pattern] Toolbar pattern differs from file-navigator: 2 controls (1 stateful action button + search) vs 6 controls. Action button has 6 states driven by focus target + step state.
- Completed workflow-viewer-spec.md v1.0 with 20 sections, 11 step types, 4 states, full EventBus contract
## Session: 2026-03-11 — Phase 2 (workflow-viewer)

- Starting Phase 2 mock build for workflow-viewer window widget
- [fixed] StepState name collision with Flutter's material.dart StepState -- used `hide StepState` on material import in flowchart_node.dart
- [pattern] Flowchart rendered via Stack of positioned widgets + CustomPaint for elbow connectors, inside nested SingleChildScrollView (X+Y)
- [pattern] Layout algorithm: topological sort on links, row assignment by step kind rules, ViewSteps share parent row, JoinSteps at half-space
- [pattern] Mock data service builds 65-step reference workflow matching stage.tercen.com spec (5 groups, 2 tables, 1 join, ~30 data steps, ~15 views, export)
- [workaround] Hexagon shape uses ClipPath + custom painter for border since BoxDecoration border does not follow clip
- [pattern] Action button state derived from aggregate step states when workflow root focused, individual step state when step focused
- [pattern] Slow double-click rename: tracks lastClickTime, triggers edit if 500-2000ms between clicks on already-focused node
- Build verified: flutter build web --wasm succeeded
## Session: 2026-03-12 — Phase 1
- Writing chat-box functional spec (window kind, Window 2 in the platform)
- [skill-gap] Window template (template-window.md) is a stub with no discovery process or spec structure — using workflow-viewer and file-navigator specs as structural references instead
- [pattern] Chat Box spec follows 20-section structure from workflow-viewer and file-navigator: Purpose, Context, Architecture, Model, Toolbar, Message List, Markdown Rendering, Input Area, Sessions, Focus Context, Action Intents, EventBus, Services, Mock Data, Dependencies, Exclusions, Wireframe, LLM Integration, Decisions, Open Questions
- Completed chat-box-spec.md v1.0 with 20 sections, 3 mock conversations, bidirectional EventBus contract, flutter_chat_ui + flutter_markdown dependencies

## Session: 2026-03-12 — Phase 2

- Starting Phase 2 mock build for chat-box window widget
- [workaround] Spec recommends flutter_chat_ui for message list mechanics -- not used because its opinionated styling conflicts with design token system. Built custom ChatMessageList with auto-scroll suppression instead.
- [fixed] Import paths: widgets in presentation/widgets/ used ../../providers/ (resolves to lib/providers/) instead of ../providers/ (resolves to lib/presentation/providers/)
- [fixed] window_body.dart copied from skeleton referenced WindowStateProvider -- replaced with ChatProvider
- [pattern] ChatProvider extends ChangeNotifier directly (not WindowStateProvider) because chat state model differs significantly from generic window state (sessions, messages, isSending, focusContext)

## Session: 2026-03-16 — Phase 1
- Writing document-editor functional spec (Window 4 in the platform)
- [pattern] Dual-mode editor: Source mode (raw markdown like code editor) + Rendered mode (WYSIWYG with formatting toolbar). Content types: .md and .txt (view+edit). PDF deferred to separate widget.
- [skill-gap] Window template (template-window.md) is still a stub -- used chat-box and workflow-viewer specs as structural references (same gap noted in 2026-03-12 session)
- [pattern] No Empty body state for document-editor -- window only opens when a file is selected. Three states: Loading, Active, Error.
- [pattern] Formatting toolbar fits inside standard 48px toolbar bar with visual group separators, avoiding a second toolbar row
- Completed document-editor-spec.md v1.0 with 20 sections, dual-mode editing, 13 formatting controls, image-from-URL, explicit save
- Updated to v1.2: resolved all 6 open questions, added toolbar responsive collapse (Section 5.9), image size selector in dialog (Section 5.6), 6 new decisions (15-20), zero open questions remaining
- Updated to v1.3: fixed 4 reviewer non-conformance issues (pixel values, hex codes, Dart tokens)
- Updated to v1.4: fixed 18 style violations -- removed ALL appearance language (fonts, colours, sizes, visual adjectives). Spec is now purely functional/behavioural. Copied final spec to _local.
## Session: 2026-03-16 — Phase 2 (document-editor)
- Starting Phase 2 mock build for document-editor window widget
- [pattern] DocumentProvider extends ChangeNotifier directly (not WindowStateProvider) because document state model differs significantly from generic window state (content, editMode, dirty tracking, save flow) -- same pattern as ChatProvider
- [workaround] flutter_markdown imageBuilder is deprecated in favour of sizedImageBuilder -- suppressed with ignore comment, sizedImageBuilder API not yet stable
- [workaround] url_launcher not added as dependency -- used web package window.open() directly for link taps in mock
- [pattern] Formatting toolbar collapses to FormatPopover dialog at narrow widths (<680px) preserving mode toggle and Save visibility
- [workaround] Full WYSIWYG editing not implemented in Phase 2 mock -- rendered mode shows read-only markdown, editing done via source mode or toolbar formatting actions that modify underlying source
- [fixed] Dollar sign in R code mock data caused Dart string interpolation -- used \${''}count escape pattern
- Build verified: flutter build web --wasm succeeded
