---
name: phase-3-primitives
description: Fill SDUI primitive gaps identified in the Phase 2 gap report. Creates or extends primitives in the sdui package, updates tokens if needed.
argument-hint: "[path to gap-report.md]"
disable-model-invocation: true
---

**READ-ONLY. Do NOT modify. Log gaps to `_issues/session-log.md` and continue.**

## Input

The gap report at `widgets/{name}/_mock/gap-report.md`.

**If no gaps:** Skip this phase. Proceed directly to Phase 4.

---

## For Each Gap, by Category

### Primitive Gap (new primitive needed)

1. Read existing primitives in `../sdui/lib/src/registry/builtin_widgets.dart` and `behavior_widgets.dart` for the registration pattern
2. Create the builder function following existing patterns:
   - Use `PropConverter.to<T>()` for all prop reads
   - Use `_resolveColor()` for colour props
   - Use `ctx.theme` for theme tokens
   - Stateful widgets: follow the `_SduiCheckbox` / `_SduiSwitch` pattern
   - Publish to EventBus on interaction: `ctx.eventBus.publish(channel, EventPayload(...))`
3. Register with `registry.register(name, builder, metadata: WidgetMetadata(...))`
4. Declare ALL handled props in `WidgetMetadata.props`
5. Run `cd ../sdui && dart analyze lib/`

### Variant Gap (new variant of existing primitive)

1. Locate the existing primitive's builder
2. Add the new variant as a prop option or a new registered type
3. Update `WidgetMetadata.props` to include the new variant
4. Run `cd ../sdui && dart analyze lib/`

### Prop Gap (missing prop on existing primitive)

1. Add prop handling to the builder function
2. Add to `WidgetMetadata.props` map
3. Run `cd ../sdui && dart analyze lib/`

### Style Gap (missing token)

1. Update `SduiTheme.dart` if a new colour/spacing/etc. is needed
2. Update `../tercen-style/tokens.meta.json` with approval flag
3. Regenerate theme export: `cd ../sdui && flutter test tool/run_export.dart`
4. Regenerate style guide: `cd ../tercen-style && node scripts/generate-style-guide.js`

### Composition Question (achievable with existing primitives)

1. Document the composition pattern in `gap-report.md` (update it with the solution)
2. No code changes needed

---

## After All Gaps Filled

Run these steps in order:

1. **Dart analyze:** `cd ../sdui && dart analyze lib/` — must pass with no errors
2. **Regenerate theme export:** `cd ../sdui && flutter test tool/run_export.dart > ../tercen-style/theme-export.json`
3. **Regenerate style guide:** `cd ../tercen-style && node scripts/generate-style-guide.js`

---

## Checklist

- [ ] All primitive gaps created and registered
- [ ] All variant/prop gaps filled
- [ ] All style gaps resolved
- [ ] `dart analyze` passes on sdui package
- [ ] `theme-export.json` regenerated
- [ ] `style-guide.html` regenerated
- [ ] `gap-report.md` updated with resolutions
