# Issue #6: Dev Files and Chat Assets Organization

**Category**: Project Organization

**Severity**: Low - Keeps repository clean

## Problem

Development and planning files accumulate in project:
- Conversation transcripts
- Planning documents
- Technical specifications
- Temporary test files
- Claude Code settings

Need organized structure that doesn't clutter repository.

## Solution

Use consistent `.gitignore` patterns and organized folder structure.

## Recommended .gitignore Patterns

```gitignore
# Miscellaneous
*.class
*.log
*.pyc
*.swp
.DS_Store
.atom/
.build/
.buildlog/
.history
.svn/

# IntelliJ related
*.iml
*.ipr
*.iws
.idea/

# Flutter/Dart/Pub related
**/doc/api/
.dart_tool/
.flutter-plugins-dependencies
.pub-cache/
.pub/
/build/          # Ignore all build
!/build/web/     # EXCEPT this - Tercen requirement
/coverage/

# Claude Code and development files
.claude/settings.local.json
chat_review/
tmp/
tmpclaude-*

# Technical documentation (template files)
FLUTTER_TECHNICAL_SPECIFICATION.md

# Temporary files
nul
*.tmp

# Platform-specific (web-only project)
/android/
/ios/
/windows/
/linux/
/macos/
```

## Recommended Folder Structure

### What to Commit

```
project-root/
├── .claude/
│   ├── plans/             # Committed - useful for reference
│   └── skills/            # Committed - team knowledge
│
├── docs/                  # Optional - committed documentation
│   ├── ARCHITECTURE.md
│   ├── DEPLOYMENT.md
│   └── PATTERNS.md
│
├── README.md              # Required - Tercen documentation
│
└── operator.json          # Required - Tercen metadata
```

### What to Ignore

```
project-root/
├── .claude/
│   └── settings.local.json  # Ignored - personal settings
│
├── chat_review/           # Ignored - conversation transcripts
│   ├── 1_conversation.md
│   ├── 2_conversation.md
│   └── ...
│
├── tmp/                   # Ignored - temporary files
│   └── scratch/
│
└── tmpclaude-*/           # Ignored - temporary Claude files
```

## Folder Purposes

### .claude/

**Committed**:
- `plans/` - Implementation plans (useful reference)
- `skills/` - Team knowledge and patterns

**Ignored**:
- `settings.local.json` - Personal Claude Code settings

### chat_review/

**Always ignored**:
- Conversation transcripts
- Raw chat exports
- Development discussions

**Purpose**: Historical reference, not needed in repository

### docs/

**Optionally committed**:
- Architecture documentation
- Deployment guides
- Pattern documentation

**Use when**: Complex projects needing extensive documentation

### tmp/ and tmpclaude-*/

**Always ignored**:
- Temporary test files
- Scratch files
- One-off experiments

## Claude Code Settings

### Global Settings

Located at: `~/.claude/settings.json`

Applies to all projects.

### Local Settings

Located at: `.claude/settings.local.json`

**Always add to .gitignore**:

```gitignore
.claude/settings.local.json
```

## File Organization Best Practices

### Planning Documents

Store in `.claude/plans/`:

```
.claude/plans/
├── feature-x-plan.md          # Committed - useful reference
├── architecture-decision.md   # Committed - team knowledge
└── scratch-notes.md           # Can be ignored if temporary
```

### Conversation Transcripts

Store in `chat_review/` (ignored):

```
chat_review/
├── 1_initial_setup.md
├── 2_authentication_fix.md
├── 3_tiff_conversion.md
└── 4_deployment_testing.md
```

### Technical Specifications

Option 1: Ignore template files
```gitignore
FLUTTER_TECHNICAL_SPECIFICATION.md
```

Option 2: Commit as team reference
```
docs/FLUTTER_TECHNICAL_SPECIFICATION.md  # Committed
```

## Cleaning Up Clutter

### Remove Ignored Files

```bash
# See what would be removed
git clean -n -d -X

# Actually remove ignored files
git clean -f -d -X

# Be careful: This deletes files permanently!
```

### Reorganize Existing Files

```bash
# Move conversation transcripts
mkdir -p chat_review
mv *_conversation*.md chat_review/

# Move planning documents
mkdir -p .claude/plans
mv *_plan.md .claude/plans/

# Move technical docs
mkdir -p docs
mv *_TECHNICAL_*.md docs/
```

## What NOT to Commit

### Never Commit

- Personal settings (`.claude/settings.local.json`)
- Conversation transcripts (`chat_review/`)
- Temporary files (`tmp/`, `tmpclaude-*`)
- Local credentials or tokens
- IDE-specific settings (unless team standard)

### Sometimes Commit

- Planning documents (if useful for team)
- Skills documentation (if team knowledge)
- Technical specifications (if architecture reference)

### Always Commit

- `operator.json` - Required by Tercen
- `README.md` - Required by Tercen
- `build/web/` - Required by Tercen (see Issue #2)
- Source code (`lib/`, `web/`)
- Tests (`test/`)
- Assets (`assets/`)

## Git Status Hygiene

Clean git status shows only meaningful changes:

```bash
git status
# On branch master
# Changes not staged for commit:
#   modified:   lib/main.dart
#   modified:   build/web/main.dart.js
#
# Untracked files:
#   (none - all dev files ignored)
```

NOT:

```bash
git status
# Untracked files:
#   chat_review/5_conversation.md
#   tmp/test123.dart
#   tmpclaude-abc/
#   .claude/settings.local.json
# (cluttered with dev files)
```

## Repository Size Management

### Keep Repository Small

Ignore:
- Large temporary files
- Generated documentation
- Conversation histories
- Scratch files

Commit only:
- Essential source code
- Required Tercen files
- Useful team documentation

### Checking Repository Size

```bash
# Check .git directory size
du -sh .git

# If too large, investigate with:
git count-objects -vH
```

## Team Workflow

### Developer A

```bash
# Creates plan
# Stored in .claude/plans/ (committed)

# Has conversation with Claude
# Transcript saved to chat_review/ (ignored)

# Updates skills
# Stored in .claude/skills/ (committed)
```

### Developer B

```bash
# Clones repository
git clone https://github.com/tercen/project

# Gets committed plans and skills
# Does NOT get Developer A's conversation transcripts (ignored)
```

## See Also

- [Issue #2: build/web/ Must Be Committed](2-build-web-commit.md)
- [Issue #5: Tercen-Required File Structure](5-tercen-file-structure.md)
- [Skill 0: Flutter Foundation](../skills/0-flutter-foundation.md)
