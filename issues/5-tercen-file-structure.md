# Issue #5: Tercen-Required File Structure

**Category**: Project Structure / Deployment

**Severity**: Critical - Required for Tercen deployment

## Problem

Tercen expects specific files in specific locations. Missing or misconfigured files prevent deployment.

## Required Files

### 1. operator.json (Root Directory)

**Location**: `operator.json` (project root)

**Purpose**: Tercen operator metadata

**Template**:

```json
{
  "name": "Your Operator Name",
  "description": "Brief description of what the operator does",
  "isWebApp": true,
  "isViewOnly": false,
  "entryType": "app",
  "tags": ["workflow"],
  "authors": ["tercen"],
  "urls": ["https://github.com/tercen/your-repo-name"],
  "serve": "build/web",
  "properties": [],
  "auth": [""]
}
```

**Critical Fields**:
- `"isWebApp": true` - Must be true for Flutter apps
- `"serve": "build/web"` - **MUST** point to build/web directory
- `"urls"`: GitHub repository URL

### 2. build/web/ Directory

**Location**: `build/web/` (entire directory)

**Purpose**: Compiled Flutter web application

**How to Create**:

```bash
flutter build web --wasm
```

**Must Be Committed**: See [Issue #2](2-build-web-commit.md)

### 3. README.md

**Location**: `README.md` (project root)

**Purpose**: Documentation for Tercen users

**Template**:

```markdown
# Operator Name

Brief description of what this operator does.

## Overview

Detailed description of functionality and use cases.

## Usage in Tercen

1. Open workflow
2. Add operator step
3. Configure inputs
4. Run

## Inputs

Describe expected inputs (files, parameters, etc.)

## Outputs

Describe what the operator produces.

## Development

Local development instructions:

```bash
# Install dependencies
flutter pub get

# Run locally
flutter run -d chrome

# Build for Tercen
flutter build web --wasm
```

## Deployment

Tercen pulls from this GitHub repository.

Changes require:
1. Code changes
2. `flutter build web --wasm`
3. Commit `build/web/` directory
4. Push to GitHub
```

### 4. web/index.html

**Location**: `web/index.html`

**Critical Requirement**: Line 17 commented

See [Issue #4: index.html Line 17](4-index-html-line17.md)

### 5. .gitignore

**Location**: `.gitignore` (project root)

**Critical Pattern**:

```gitignore
/build/          # Ignore all
!/build/web/     # EXCEPT this
```

See [Issue #2: build/web/ Must Be Committed](2-build-web-commit.md)

## Complete Directory Structure

```
project-root/
├── operator.json          # Tercen metadata (REQUIRED)
├── README.md              # Documentation (REQUIRED)
├── pubspec.yaml           # Flutter dependencies
├── .gitignore             # With build/web/ exception
│
├── lib/                   # Dart source code
│   ├── main.dart
│   ├── di/                # Dependency injection
│   ├── domain/            # Abstract interfaces
│   ├── implementations/   # Concrete implementations
│   ├── presentation/      # UI (screens, widgets, providers)
│   └── utils/             # Utilities
│
├── web/                   # Web-specific files
│   ├── index.html         # Line 17 commented (REQUIRED)
│   ├── manifest.json
│   └── icons/
│
├── build/                 # Build artifacts
│   └── web/               # MUST be committed (REQUIRED)
│       ├── index.html
│       ├── main.dart.js
│       ├── flutter.js
│       ├── assets/
│       └── ...
│
├── assets/                # App assets (images, fonts, etc.)
│
└── test/                  # Tests
    ├── unit/
    ├── widget/
    └── integration/
```

## Verification Checklist

Before first deployment to Tercen:

- [ ] `operator.json` exists in root
- [ ] `operator.json` has `"serve": "build/web"`
- [ ] `operator.json` has `"isWebApp": true`
- [ ] `operator.json` has correct GitHub URL
- [ ] `README.md` exists with Tercen usage instructions
- [ ] `web/index.html` line 17 is commented
- [ ] `.gitignore` has `/build/` and `!/build/web/` pattern
- [ ] `build/web/` directory exists and is committed
- [ ] `flutter build web --wasm` completes successfully

## Common Mistakes

### ❌ WRONG: Missing operator.json

```
Error: Tercen can't find operator metadata
```

### ❌ WRONG: Incorrect serve path

```json
{
  "serve": "web"  // Wrong - should be "build/web"
}
```

### ❌ WRONG: build/web/ not committed

```bash
git status
# On branch master
# Untracked files:
#   build/web/  # This should be TRACKED
```

## operator.json Field Reference

### Required Fields

- `name` (string): Display name in Tercen
- `isWebApp` (boolean): Must be `true`
- `serve` (string): Must be `"build/web"`

### Optional Fields

- `description` (string): Operator description
- `entryType` (string): Type of operator ("app", "operator", etc.)
- `tags` (array): Tags for categorization
- `authors` (array): Author names
- `urls` (array): Repository URLs
- `properties` (array): Configuration properties
- `auth` (array): Authentication requirements
- `isViewOnly` (boolean): Read-only mode

## Example operator.json

```json
{
  "name": "Your Operator Name",
  "description": "Brief description of what this operator does",
  "isWebApp": true,
  "isViewOnly": false,
  "entryType": "app",
  "tags": ["workflow", "visualization"],
  "authors": ["tercen"],
  "urls": ["https://github.com/tercen/your-operator-repo"],
  "serve": "build/web",
  "properties": [],
  "auth": [""]
}
```

## Testing File Structure

```bash
# Verify all required files
ls -la operator.json
ls -la README.md
ls -la web/index.html
ls -la build/web/index.html

# Verify operator.json content
cat operator.json | grep "serve"
# Should output: "serve": "build/web",

# Verify index.html
grep "base href" web/index.html
# Should output: <!--<base href="$FLUTTER_BASE_HREF"> -->

# Verify build/web/ is tracked
git ls-files build/web/ | head -5
# Should list files (not empty)
```

## See Also

- [Issue #1: WASM Build](1-wasm-build.md)
- [Issue #2: build/web/ Must Be Committed](2-build-web-commit.md)
- [Issue #4: index.html Line 17](4-index-html-line17.md)
- [Skill 2: Tercen Real Implementation](../skills/2-tercen-real.md)
