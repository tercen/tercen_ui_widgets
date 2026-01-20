# Issue #7: Hot Reload Does NOT Work - Stop and Restart Required

**Category**: Development Workflow

**Severity**: High - Wastes developer time and causes confusion

## Problem

Flutter web's hot reload feature does NOT work reliably:
- Pressing `r` (hot reload) doesn't show changes
- Pressing `R` (hot restart) also unreliable
- Developers waste time debugging "broken" code that actually works
- Creates false impression that code isn't working

## Impact

- Developers think their changes aren't working when they actually are
- Time wasted debugging phantom issues
- Frustration when changes "randomly" don't appear
- Confusion about whether code or tooling is broken

## Reality

**Hot reload is BROKEN for Flutter web** - This is not your code's fault.

### What Doesn't Work

```bash
# Start app
flutter run -d chrome

# Make code changes

# Press 'r' for hot reload
r
# ✗ Changes DO NOT appear

# Press 'R' for hot restart
R
# ✗ Changes STILL DO NOT appear reliably
```

### What DOES Work

```bash
# Start app
flutter run -d chrome

# Make code changes

# Stop the app completely
Ctrl+C

# Restart from scratch
flutter run -d chrome
# ✓ Changes NOW appear
```

## Required Workflow

### ALWAYS Stop and Restart

```
1. Make code changes
2. Stop app (Ctrl+C or Stop button in IDE)
3. Restart app (flutter run -d chrome)
4. Changes are now visible
```

**DO NOT** rely on hot reload or hot restart - they are broken.

## Why This Happens

Flutter web compiles to JavaScript:
- Hot reload tries to inject changes into running JavaScript
- JavaScript doesn't support hot reloading like Dart VM does
- Browser caching interferes with updates
- Only full restart ensures JavaScript is recompiled and loaded

## Standard Operating Procedure

Make this your default workflow:

```bash
# Save file in editor
Ctrl+S

# Terminal: Stop running app
Ctrl+C

# Terminal: Restart app
flutter run -d chrome

# Or use IDE keyboard shortcut:
# Stop: Shift+F5
# Run: F5
```

## IDE Integration

### VS Code

Create keyboard shortcut for "Stop → Run":

```json
// keybindings.json
{
  "key": "ctrl+shift+r",
  "command": "workbench.action.debug.restart",
  "when": "inDebugMode"
}
```

### IntelliJ / Android Studio

Use built-in "Rerun" button (Ctrl+F5):
- Stops current run
- Starts new run
- Single action for full restart

## Time Expectations

**Per-change iteration time**: 5-10 seconds
- Stop app: 1-2 seconds
- Restart app: 3-5 seconds
- Page load: 1-2 seconds

**Fast enough** for productive development.

## Common Mistakes

### ❌ WRONG: Trusting hot reload

```
1. Make changes
2. Press 'r'
3. Don't see changes
4. Spend 10 minutes debugging code that actually works
```

### ❌ WRONG: Repeatedly trying hot reload

```
1. Press 'r' - nothing
2. Press 'R' - nothing
3. Press 'r' again - nothing
4. Give up and restart (should have done this first!)
```

### ✅ CORRECT: Always stop and restart

```
1. Make changes
2. Ctrl+C (stop)
3. Up arrow + Enter (restart)
4. Changes appear immediately
```

## Muscle Memory Training

Train yourself to automatically:

```
Ctrl+S (save)
Ctrl+C (stop)
Up arrow (previous command)
Enter (run again)
```

This becomes second nature after a few iterations.

## Special Case: Build for Tercen

For Tercen deployment, you can't use `flutter run` at all:

```bash
# REQUIRED for Tercen testing
flutter build web --wasm

# Hot reload not even an option
# Must rebuild completely for each test
```

See [Issue #1: WASM Build & Tercen Testing](1-wasm-build.md) for full workflow.

## When Hot Reload Might Work

Hot reload CAN work for:
- Flutter mobile (Android/iOS) - reliable
- Flutter desktop (Windows/Mac/Linux) - mostly reliable
- Flutter web - **DOES NOT WORK RELIABLY**

Don't assume Flutter web behaves like mobile.

## Verification

How to know if change actually applied:

```dart
// Add timestamp to verify new code loaded
print('🔧 App initialized: ${DateTime.now()}');

// Add version number
print('📋 Version: 1.2.3');

// Stop → Restart → Should see new timestamp
```

## Team Communication

Tell your team explicitly:

> "Hot reload doesn't work for Flutter web. Always stop and restart to see changes. This is normal and expected."

Prevents 30+ minutes of confusion when onboarding new developers.

## Workarounds That Don't Help

**Tried and failed**:
- Clear browser cache - doesn't help
- Hard refresh (Ctrl+Shift+R) - doesn't help
- Close and reopen browser - doesn't help
- `flutter clean` - doesn't help

**Only solution**: Stop → Restart

## Impact on Development Speed

**With hot reload (mobile)**: ~2 seconds per iteration
**Without hot reload (web)**: ~8 seconds per iteration

**4x slower**, but still acceptable for web development.

## Documentation for Users

Add to project README.md:

```markdown
## Development Notes

**CRITICAL**: Hot reload does NOT work for Flutter web.

After making changes:
1. Stop the app (Ctrl+C)
2. Restart: `flutter run -d chrome`

DO NOT waste time pressing 'r' or 'R' - they don't work.
```

## See Also

- [Issue #1: WASM Build & Tercen Testing](1-wasm-build.md)
- [Issue #8: Mandatory Development Workflow](8-mandatory-workflow.md)
- [Skill 1: Tercen Mock Implementation](../skills/1-tercen-mock.md)
