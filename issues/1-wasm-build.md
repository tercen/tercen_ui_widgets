# Issue #1: WASM Build & Tercen Testing Workflow

**Category**: Deployment

**Severity**: High - Affects testing cycle time

## Problem

Building with `--wasm` and testing in Tercen creates a slow feedback loop:
- Each test requires full rebuild
- Build outputs must be committed to Git
- Tercen pulls from GitHub repository
- No local testing equivalent to Tercen environment

## Impact

- Slow iteration during development
- Difficult debugging of deployment-specific issues
- Easy to forget build/commit/push cycle
- Changes that work locally may fail in Tercen

## Required Workflow

### Build Command

```bash
# CRITICAL: Always build with --wasm for Tercen deployment
flutter build web --wasm
```

**NOT** `flutter run -d chrome` - behaviors differ from Tercen deployment.

### Full Testing Cycle

```bash
# 1. Make code changes

# 2. Build for Tercen
flutter build web --wasm

# 3. Verify build/web/ updated
ls -la build/web/

# 4. Commit build/web/ changes
git add build/web/
git commit -m "Rebuild web app with [describe changes]"

# 5. Push to GitHub
git push

# 6. Wait for Tercen to pull changes (may take 1-2 minutes)

# 7. Test in Tercen environment
# Open app in Tercen workflow or standalone mode
```

## Why This Matters

Tercen serves the compiled Flutter app from `build/web/`:

- `operator.json` specifies `"serve": "build/web"`
- Tercen reads from GitHub repository
- No direct local→Tercen testing path
- Must go through full build→commit→push cycle

## Time-Saving Strategies

### 1. Use Mock Implementation Locally First

```dart
// Develop with mocks using flutter run
flutter run -d chrome

// Only switch to Tercen when mocks work perfectly
flutter build web --wasm
```

### 2. Batch Changes Before Rebuilding

Don't rebuild after every line change:
- ✓ Make multiple related changes
- ✓ Test thoroughly with mocks locally
- ✓ Then rebuild once for Tercen

### 3. Use Debug Logging

Add comprehensive logging to diagnose issues faster:

```dart
print('🔍 URL: ${Uri.base}');
print('📋 Path segments: ${Uri.base.pathSegments}');
print('✓ Loaded ${files.length} files');
```

### 4. Understand What Changes Require Rebuild

**Requires rebuild**:
- Any Dart code changes
- pubspec.yaml dependency changes
- Asset additions/modifications
- index.html changes

**Does NOT require rebuild**:
- README.md changes
- Documentation updates
- Comments in code (technically yes, but no functional difference)

## Development Workflow Recommendation

```
Phase 1: Local Development (Fast Iteration)
  ├─ flutter run -d chrome
  ├─ Use mock data
  ├─ Iterate quickly on UI/UX
  └─ Stop and restart (NOT hot reload) for each change

Phase 2: Tercen Integration (Slower Iteration)
  ├─ Switch to real Tercen API
  ├─ flutter build web --wasm
  ├─ git add/commit/push
  ├─ Test in Tercen
  └─ Debug with extensive logging

Phase 3: Final Testing
  ├─ Test both standalone and workflow modes
  ├─ Verify on Tercen stage environment
  └─ Verify on Tercen production
```

## Common Mistakes

### ❌ WRONG: Using `flutter run` for Tercen testing

```bash
flutter run -d chrome
# Test locally
# Assume it will work in Tercen
```

**Problem**: Local dev server behaves differently than Tercen deployment.

### ❌ WRONG: Forgetting to commit `build/web/`

```bash
flutter build web --wasm
git commit -m "Fix bug" lib/
git push
# Tercen still serves old build/web/ - bug persists!
```

### ✅ CORRECT: Full workflow

```bash
flutter build web --wasm
git add build/web/
git commit -m "Fix bug: update logic in XYZ"
git push
# Wait for Tercen to refresh
# Test in Tercen
```

## Verification Checklist

Before pushing to Tercen:

- [ ] Ran `flutter build web --wasm`
- [ ] Verified `build/web/` directory updated (check timestamps)
- [ ] Tested with mock data locally first
- [ ] Added debug logging for troubleshooting
- [ ] Committed `build/web/` directory
- [ ] Pushed to GitHub
- [ ] Waited 1-2 minutes for Tercen to refresh

## Troubleshooting

### Build Appears Not to Update

```bash
# Force clean build
flutter clean
flutter pub get
flutter build web --wasm

# Verify build timestamp
ls -la build/web/main.dart.js
```

### Tercen Shows Old Version

1. Check GitHub - did push succeed?
2. Wait 2-3 minutes (Tercen caching)
3. Hard refresh in browser (Ctrl+Shift+R)
4. Check operator version in Tercen

### Build Fails

```bash
# Check for errors
flutter build web --wasm --verbose

# Common fixes
flutter clean
rm -rf build/
flutter pub get
flutter build web --wasm
```

## Expected Iteration Time

Realistic expectations:

- **Local mock development**: 5-10 seconds per change (stop/restart)
- **Tercen deployment test**: 2-5 minutes per change (build/commit/push/refresh)

**Recommendation**: Do 10-20 local iterations before 1 Tercen test.

## See Also

- [Issue #2: build/web/ Must Be Committed](2-build-web-commit.md)
- [Issue #5: Tercen-Required File Structure](5-tercen-file-structure.md)
- [Issue #7: Hot Reload Does NOT Work](7-hot-reload-broken.md)
- [Skill 1: Tercen Mock Implementation](../skills/1-tercen-mock.md)
- [Skill 2: Tercen Real Implementation](../skills/2-tercen-real.md)
