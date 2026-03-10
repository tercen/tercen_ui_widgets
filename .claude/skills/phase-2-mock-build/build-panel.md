# Phase 2 Mock Build — Panel Widget

Steps 2-7 for building a panel widget. Step 1 (Copy and Rename) is in `SKILL.md`.

Source skeleton: `skeletons/panel/`

For shared patterns: `_references/global-rules.md`.

---

## Step 2: Define Domain Models

Read spec **Section 2.2** and **Section 7.3**.

Create model classes in `lib/domain/models/` from the spec's data columns and types.

Update `lib/domain/services/data_service.dart` — replace `Map<String, dynamic>` with domain types. Add multiple methods if the spec requires distinct operations.

---

## Step 3: Build Mock Service

Read spec **Section 7.3**.

1. Put data files in `assets/data/`. Register in `pubspec.yaml` under `flutter: assets:`.
2. Replace `mock_data_service.dart` — load from `rootBundle.loadString()` (text) or `rootBundle.load()` (binary).
3. Must return real data from assets — not placeholder values.

---

## Step 4: Build Provider

Read spec **Section 4.2** — every control becomes a provider field.

Replace `app_state_provider.dart`. For each control: private field + getter + setter calling `notifyListeners()`. Keep the data loading infrastructure (`loadData`, `isLoading`, `error`, `data`). Update `data` type to your domain model.

Wiring: `control.onChanged → provider.setXxx(value) → notifyListeners() → Consumer rebuilds`. See `_references/global-rules.md` and skeleton `controls_section.dart` for all 11 control patterns.

---

## Step 5: Build Left Panel Sections

Read spec **Section 4.2**.

Create one widget per section in `lib/presentation/widgets/left_panel/`. Use control types and styling from `_references/global-rules.md` and skeleton `controls_section.dart`.

Wire into `home_screen.dart` `sections:` list — one `PanelSection` per spec section with icon, UPPERCASE label, and content widget. INFO always last.

---

## Step 6: Build Main Content

Read spec **Section 4.3**.

Replace `_MainContent` in `home_screen.dart`. Reads from provider, renders spec visualization. Handle `isLoading` and `error` states.

**Theme:** Main panel chrome is theme-aware. Graph/chart containers force white background (see `_references/global-rules.md`).

**Line weights:** All `strokeWidth` must use `AppLineWeights.*` constants — no hardcoded numbers.

**Display only.** No controls in main content. Spec-described interactions (hover, click-to-select, zoom) are read-only feedback.

---

## Step 7: Verify

Run `flutter run -d chrome`. Verify against the checklist at the end of this document.

---

## DO NOT MODIFY

Copy these files unchanged from `skeletons/panel/`.

| File | What it does |
|---|---|
| `lib/presentation/widgets/left_panel/left_panel.dart` | Collapse, expand, resize, LayoutBuilder, icon strip, footer chevron |
| `lib/presentation/widgets/left_panel/left_panel_header.dart` | 4-element header, collapsed header restructuring |
| `lib/presentation/widgets/left_panel/left_panel_section.dart` | Section header styling (background, text color, borders) |
| `lib/presentation/widgets/app_shell.dart` | Frame layout, conditional top bar |
| `lib/presentation/widgets/top_bar.dart` | Standalone mode indicator |
| `lib/core/theme/app_colors.dart` | Light theme color tokens |
| `lib/core/theme/app_colors_dark.dart` | Dark theme color tokens |
| `lib/core/theme/app_spacing.dart` | Spacing and dimension tokens |
| `lib/core/theme/app_text_styles.dart` | Typography tokens |
| `lib/core/theme/app_theme.dart` | Material 3 ThemeData (light + dark) |
| `lib/core/theme/app_line_weights.dart` | Line weight constants for UI and viz |
| `lib/core/utils/context_detector.dart` | Tercen embedded detection |
| `lib/presentation/providers/theme_provider.dart` | Theme persistence |
| `lib/di/service_locator.dart` | DI registration (add services, don't restructure) |
| `lib/main.dart` | Entry point (rename class + title only, don't restructure) |

If panel collapse, resize, or theme toggle breaks — a DO NOT MODIFY file was changed. Revert.

---

## Files You Create or Replace

| File | Action |
|---|---|
| `lib/domain/models/*.dart` | Create — domain model classes from spec Section 2.2 |
| `lib/domain/services/*.dart` | Replace or create — update return types, add service interfaces as needed |
| `lib/implementations/services/*.dart` | Replace or create — one mock implementation per service interface |
| `lib/presentation/providers/app_state_provider.dart` | Replace — one field per control from spec Section 4.2. Split into multiple providers if the spec has distinct state domains (e.g., separate navigation, settings, data). |
| `lib/presentation/screens/home_screen.dart` | Replace — sections list + main content from spec |
| `lib/presentation/widgets/left_panel/*_section.dart` | Create — one per spec section (except info_section.dart, which stays) |
| `assets/data/*` | Create — mock data files from spec Section 7.3 |
| `pubspec.yaml` | Edit — name, description, assets |
| `operator.json` | Edit — name, description, urls |
| `lib/core/version/version_info.dart` | Edit — gitRepo, version |

Delete the skeleton's demo files after replacing them:
- `controls_section.dart` (replaced by your widget's sections)
- `buttons_section.dart` (replaced by your widget's sections)
- `settings_section.dart` (unused)
- `filters_section.dart` (unused)

---

## Checklist

Before completing Phase 2:

- [ ] Widget runs with `flutter run -d chrome` — no errors
- [ ] All sections from spec Section 4.2 present with correct icons and UPPERCASE labels
- [ ] All controls have correct types, defaults, and ranges from spec
- [ ] Every control updates main content via the provider (wiring golden rule)
- [ ] Main content matches spec Section 4.3
- [ ] Mock data loaded from assets (not hardcoded placeholder values)
- [ ] Panel collapse/expand/resize works identically to skeleton
- [ ] Theme toggle works (light + dark) — chrome only, graph area stays white
- [ ] INFO section present with correct GitHub URL
- [ ] No controls in the main content area
- [ ] No modifications to DO NOT MODIFY files
- [ ] `flutter build web --wasm` succeeds
- [ ] User has reviewed and approved the mock widget
