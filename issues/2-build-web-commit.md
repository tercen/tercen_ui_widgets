# Issue #2: build/web/ Must Be Committed

**Category**: Git / Deployment

**Severity**: Critical - Breaks Tercen deployment

## Problem

Tercen serves compiled Flutter app from `build/web/` directory in GitHub repository.

Standard Flutter `.gitignore` ignores entire `/build/` directory, which prevents Tercen from finding the app.

## Impact

- App doesn't deploy to Tercen
- Tercen shows 404 errors
- Changes don't appear in deployed app

## Solution

Add exception to `.gitignore`:

```gitignore
# Flutter build artifacts
/build/          # Ignore all build directories
!/build/web/     # EXCEPT build/web/ - Tercen requires this
```

## Why This Is Unusual

Most Flutter projects:
- Build artifacts are generated during CI/CD
- Never commit `build/` directory
- Use `.gitignore` to exclude `/build/`

Tercen projects:
- Tercen pulls directly from GitHub
- No CI/CD build step
- Must commit `build/web/` for deployment

## Verification

```bash
# Check if build/web/ is tracked
git status

# Should NOT show:
#   build/web/ (untracked)

# Should show (after flutter build web --wasm):
#   modified:   build/web/main.dart.js
#   modified:   build/web/flutter.js
#   etc.
```

## Required .gitignore Pattern

```gitignore
# Miscellaneous
*.class
*.log
*.pyc
*.swp
.DS_Store
.build/
.buildlog/

# Flutter/Dart/Pub related
.dart_tool/
.flutter-plugins-dependencies
.pub-cache/
.pub/
/build/          # Ignore build directory
!/build/web/     # EXCEPT build/web/ - required for Tercen
/coverage/

# ... rest of standard .gitignore
```

## Workflow Impact

### Every Build Must Be Committed

```bash
# 1. Build
flutter build web --wasm

# 2. Stage build artifacts
git add build/web/

# 3. Commit with descriptive message
git commit -m "Rebuild web app: fix authentication bug"

# 4. Push to GitHub
git push

# 5. Tercen pulls updated build/web/
```

## Common Mistakes

### ❌ WRONG: Forgetting exception in .gitignore

```gitignore
/build/          # This ignores build/web/ too!
```

Result: `build/web/` never committed, Tercen can't serve app.

### ❌ WRONG: Manually adding files each time

```bash
git add build/web/index.html
git add build/web/main.dart.js
# ... tedious and error-prone
```

### ✅ CORRECT: Exception in .gitignore

```gitignore
/build/          # Ignore all
!/build/web/     # Except this
```

Now `git add build/web/` works automatically.

## File Size Considerations

`build/web/` can be large (5-20 MB):
- Compiled JavaScript
- WASM files
- Assets
- Flutter framework

**This is acceptable** - Tercen expects this.

## Cleaning Build Artifacts

```bash
# Clean everything except build/web/
flutter clean
# Deletes:
#   - .dart_tool/
#   - .flutter-plugins-dependencies
#   - Most of build/
# Preserves:
#   - build/web/ (because it's committed)

# To fully clean (including build/web/):
rm -rf build/
flutter build web --wasm
git add build/web/
git commit -m "Clean rebuild"
```

## Verification Checklist

After initial project setup:

- [ ] `.gitignore` has `/build/` line
- [ ] `.gitignore` has `!/build/web/` exception line
- [ ] Run `flutter build web --wasm`
- [ ] Run `git status` - should show `build/web/` files as modified/untracked
- [ ] Run `git add build/web/`
- [ ] Run `git commit -m "Initial build"`
- [ ] Verify commit includes `build/web/` files

## See Also

- [Issue #1: WASM Build & Tercen Testing](1-wasm-build.md)
- [Issue #5: Tercen-Required File Structure](5-tercen-file-structure.md)
- [Skill 2: Tercen Real Implementation](../skills/2-tercen-real.md)
