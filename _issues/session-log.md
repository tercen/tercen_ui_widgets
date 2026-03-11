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
