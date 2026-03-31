#!/bin/bash
# Validates catalog.json for common errors:
# - Valid JSON
# - No hex colour values in template color props
# - No unapproved colour tokens
# - Node ID uniqueness
#
# Called by Claude Code post-write hook on catalog.json

CATALOG="$1"
META="../tercen-style/tokens.meta.json"

if [ ! -f "$CATALOG" ]; then
  echo "ERROR: catalog.json not found at $CATALOG"
  exit 1
fi

ERRORS=0

# 1. Valid JSON
if ! python3 -c "import json; json.load(open('$CATALOG'))" 2>/dev/null; then
  echo "FAIL: catalog.json is not valid JSON"
  ERRORS=$((ERRORS + 1))
fi

# 2. No hex colours in template color props (typeColor in metadata is exempt)
HEX_COLORS=$(python3 -c "
import json, re
catalog = json.load(open('$CATALOG'))
hits = []
def check_node(node, path=''):
    if not isinstance(node, dict):
        return
    props = node.get('props', {})
    if isinstance(props, dict):
        for k, v in props.items():
            if k == 'color' and isinstance(v, str) and re.match(r'^#[0-9a-fA-F]+$', v):
                hits.append(f'{path}/{node.get(\"id\",\"?\")}: {k}={v}')
    for child in node.get('children', []):
        check_node(child, f'{path}/{node.get(\"id\",\"?\")}')

for w in catalog.get('widgets', []):
    template = w.get('template', {})
    check_node(template, w.get('metadata',{}).get('type','?'))
for h in hits:
    print(h)
" 2>/dev/null)

if [ -n "$HEX_COLORS" ]; then
  echo "FAIL: Hex colour values found in template color props (use approved token names):"
  echo "$HEX_COLORS"
  ERRORS=$((ERRORS + 1))
fi

# 3. Unapproved colour tokens
if [ -f "$META" ]; then
  UNAPPROVED=$(python3 -c "
import json
catalog = json.load(open('$CATALOG'))
meta = json.load(open('$META'))
colors = meta.get('colors', {})
approved = {k for k, v in colors.items() if isinstance(v, dict) and v.get('approved') == True}
deleted = set(meta.get('deletedTokens', {}).keys())
hits = []
def check_node(node, path=''):
    if not isinstance(node, dict):
        return
    props = node.get('props', {})
    if isinstance(props, dict):
        for k, v in props.items():
            if k == 'color' and isinstance(v, str) and not v.startswith('#') and not v.startswith('{'):
                if v in deleted:
                    hits.append(f'{path}/{node.get(\"id\",\"?\")}: \"{v}\" is DELETED — see PITFALLS.md for replacement')
                elif v not in approved:
                    hits.append(f'{path}/{node.get(\"id\",\"?\")}: \"{v}\" is not an approved colour token')
    for child in node.get('children', []):
        check_node(child, f'{path}/{node.get(\"id\",\"?\")}')

for w in catalog.get('widgets', []):
    template = w.get('template', {})
    check_node(template, w.get('metadata',{}).get('type','?'))
for h in hits:
    print(h)
" 2>/dev/null)

  if [ -n "$UNAPPROVED" ]; then
    echo "FAIL: Unapproved or deleted colour tokens found:"
    echo "$UNAPPROVED"
    ERRORS=$((ERRORS + 1))
  fi
fi

# 4. Node ID uniqueness
DUPES=$(python3 -c "
import json
from collections import Counter
catalog = json.load(open('$CATALOG'))
ids = []
def collect_ids(node):
    if not isinstance(node, dict):
        return
    nid = node.get('id')
    if nid and not nid.startswith('{{'):
        ids.append(nid)
    for child in node.get('children', []):
        collect_ids(child)

for w in catalog.get('widgets', []):
    collect_ids(w.get('template', {}))
dupes = {k: v for k, v in Counter(ids).items() if v > 1}
for k, v in dupes.items():
    print(f'{k} (appears {v} times)')
" 2>/dev/null)

if [ -n "$DUPES" ]; then
  echo "FAIL: Duplicate node IDs found:"
  echo "$DUPES"
  ERRORS=$((ERRORS + 1))
fi

if [ $ERRORS -eq 0 ]; then
  echo "PASS: catalog.json validation passed"
fi

exit $ERRORS
