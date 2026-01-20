# Issue #4: index.html Line 17 Must Be Commented

**Category**: Routing / Deployment

**Severity**: Critical - Breaks app in Tercen

## Problem

Flutter's default `web/index.html` contains a `<base href>` tag that conflicts with Tercen's URL routing.

If this line is NOT commented out, the app fails to load resources and routing breaks in Tercen deployment.

## The Problematic Line

```html
<!-- web/index.html line 17 -->
<base href="$FLUTTER_BASE_HREF">
```

## Required Fix

**MUST comment out line 17**:

```html
<!-- CRITICAL: This line MUST be commented for Tercen deployment -->
<!--<base href="$FLUTTER_BASE_HREF"> -->
```

## Why This Matters

Tercen serves apps at custom URL paths:
- Standalone mode: `https://tercen.com/_w3op/{documentId}/`
- Workflow mode: `https://tercen.com/w/{workflowId}/ds/{stepId}`

If `<base href>` is set:
- Flutter tries to resolve resources relative to base path
- Conflicts with Tercen's custom paths
- Resources (JS, CSS, images) fail to load
- Routing breaks completely

## Impact If Not Commented

```
✗ main.dart.js fails to load (404)
✗ flutter.js fails to load (404)
✗ Assets fail to load (404)
✗ App shows blank white screen
✗ Browser console shows multiple 404 errors
```

## Correct web/index.html

```html
<!DOCTYPE html>
<html>
<head>
  <!--
    If you are serving your web app in a path other than the root, change the
    href value below to reflect the base path you are serving from.

    The path provided below has to start and end with a slash "/" in order for
    it to work correctly.

    For more details:
    * https://developer.mozilla.org/en-US/docs/Web/HTML/Element/base

    This is a placeholder for base href that will be replaced by the value of
    the `--base-href` argument provided to `flutter build`.
  -->
  <!--<base href="$FLUTTER_BASE_HREF"> -->

  <meta charset="UTF-8">
  <meta content="IE=Edge" http-equiv="X-UA-Compatible">
  <meta name="description" content="A new Flutter project.">

  <!-- iOS meta tags & icons -->
  <meta name="mobile-web-app-capable" content="yes">
  <meta name="apple-mobile-web-app-status-bar-style" content="black">
  <meta name="apple-mobile-web-app-title" content="Your App Name">
  <link rel="apple-touch-icon" href="icons/Icon-192.png">

  <!-- Favicon -->
  <link rel="icon" type="image/png" href="favicon.png"/>

  <title>Your App Name</title>
  <link rel="manifest" href="manifest.json">
</head>
<body>
  <script src="flutter_bootstrap.js" async></script>
</body>
</html>
```

## When To Check This

### Initial Project Setup

After `flutter create`:

```bash
# 1. Create Flutter project
flutter create my_tercen_app

# 2. IMMEDIATELY edit web/index.html
# Comment out line 17

# 3. Verify
grep "base href" web/index.html
# Should see: <!--<base href="$FLUTTER_BASE_HREF"> -->
```

### After Flutter Upgrade

Flutter upgrades may regenerate `web/index.html`:

```bash
# After flutter upgrade
flutter upgrade

# RE-CHECK web/index.html line 17
# Re-comment if necessary
```

### When Adding Web Support to Existing Project

```bash
# Adding web to mobile project
flutter create --platforms=web .

# CRITICAL: Check and comment line 17 immediately
```

## Verification

```bash
# Check if line is commented
cat web/index.html | grep -n "base href"

# Should output:
17:  <!--<base href="$FLUTTER_BASE_HREF"> -->

# NOT:
17:  <base href="$FLUTTER_BASE_HREF">
```

## Testing

### Test Locally (May Still Work)

Even with uncommented line, may work on localhost:
```
http://localhost:53000/
```

### Test in Tercen (Will Fail)

Uncommented line WILL break in Tercen:
```
https://tercen.com/_w3op/abc123/
```

**Always test in Tercen** before assuming it works.

## Build Command Impact

The `--base-href` flag during build:

```bash
# DON'T use --base-href for Tercen
flutter build web --wasm
# Correct - no base href

# DON'T do this for Tercen
flutter build web --wasm --base-href /my-app/
# Wrong - will break routing
```

Tercen manages base paths itself - don't specify `--base-href`.

## Common Mistakes

### ❌ WRONG: Leaving line uncommented

```html
<base href="$FLUTTER_BASE_HREF">
```

Result: App fails to load in Tercen.

### ❌ WRONG: Removing line completely

```html
<!-- Line removed entirely -->
```

Better to comment (preserves context) than delete.

### ✅ CORRECT: Comment the line

```html
<!--<base href="$FLUTTER_BASE_HREF"> -->
```

## Troubleshooting

### Symptoms of Uncommented Base Href

1. White screen in Tercen
2. Browser console shows 404 errors
3. DevTools Network tab shows failed resource loads
4. main.dart.js returns 404

### Fix

```bash
# Edit web/index.html
# Comment line 17
# Rebuild
flutter build web --wasm

# Commit
git add web/index.html build/web/
git commit -m "Comment base href for Tercen deployment"
git push
```

## Checklist

After any change to `web/index.html`:

- [ ] Line 17 is commented: `<!--<base href="$FLUTTER_BASE_HREF"> -->`
- [ ] No other `<base>` tags added
- [ ] Rebuild: `flutter build web --wasm`
- [ ] Commit: `git add web/index.html build/web/`
- [ ] Test in Tercen deployment

## See Also

- [Issue #1: WASM Build & Tercen Testing](1-wasm-build.md)
- [Issue #5: Tercen-Required File Structure](5-tercen-file-structure.md)
- [Pattern: URL Path Parsing](../patterns/url-parsing.md)
- [Skill 2: Tercen Real Implementation](../skills/2-tercen-real.md)
