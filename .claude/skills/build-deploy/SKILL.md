---
name: build-deploy
description: Build WASM and deploy a Tercen Flutter operator to GitHub. Creates the repo in the tercen org if needed, validates operator.json, builds, commits, and pushes.
disable-model-invocation: true
argument-hint: "[path to project]"
allowed-tools: Bash, Read, Glob, Write, Edit
---

Build and deploy the Tercen Flutter operator at `$ARGUMENTS`.

## Pre-flight checks

1. Verify `operator.json` exists and contains required fields:
   - `name` — display name
   - `isWebApp` → `true`
   - `isViewOnly` → `false`
   - `entryType` → `"app"`
   - `serve` → `"build/web"`
   - `urls` → array with at least one GitHub URL matching `https://github.com/tercen/{name}_flutter_operator`

2. Verify `index.html` line 17 base href is commented out:
   `<!--<base href="$FLUTTER_BASE_HREF"> -->`

3. Verify `pubspec.yaml` `name:` matches the operator repo name

## Build

```bash
cd $ARGUMENTS
flutter build web --wasm
```

If the build fails, fix the errors and retry. Do not proceed until the build succeeds.

## GitHub repo

Check if the repo exists:

```bash
gh repo view tercen/{name}_flutter_operator 2>/dev/null
```

If it does not exist, create it:

```bash
gh repo create tercen/{name}_flutter_operator --public --description "{operator description from operator.json}"
```

Set the remote:

```bash
git remote add origin https://github.com/tercen/{name}_flutter_operator.git
```

Or verify the existing remote points to the correct repo.

## Commit and push

```bash
git add -A
git commit -m "Build and deploy web app"
git push -u origin main
```

## Post-deploy

Report to the user:
- GitHub repo URL
- Confirm build/web/ is committed
- Remind: pull the repo into Tercen to test

## Future

MCP tools for direct Tercen sync are being developed. When available, this skill
will be extended to push directly to Tercen instead of only to GitHub.
