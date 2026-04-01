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

# 5. Icon name validation — check against SDUI _iconMap and _solidIconMap
SDUI_WIDGETS="../sdui/lib/src/registry/builtin_widgets.dart"
if [ -f "$SDUI_WIDGETS" ]; then
  ICON_ERRORS=$(python3 -c "
import json, re

catalog = json.load(open('$CATALOG'))

# Extract icon maps from SDUI source
with open('$SDUI_WIDGETS') as f:
    lines = f.readlines()

regular = set()
solid = set()
in_regular = False
in_solid = False

for line in lines:
    if 'const Map<String, IconData> _iconMap' in line:
        in_regular = True; in_solid = False; continue
    if 'const Map<String, IconData> _solidIconMap' in line:
        in_solid = True; in_regular = False; continue
    if (in_regular or in_solid) and line.strip() == '};':
        in_regular = False; in_solid = False; continue
    m = re.search(r\"'(\w+)':\", line)
    if m:
        if in_regular: regular.add(m.group(1))
        elif in_solid: solid.add(m.group(1))

# FA6 Free: these icons only have solid glyphs — regular weight renders as question mark
fa6_solid_only = {'folder', 'folder_open', 'star', 'heart', 'bookmark', 'bell',
                  'comment', 'comments', 'envelope', 'calendar', 'clock', 'image',
                  'user', 'circle', 'file'}

hits = []
def check_icons(node, widget_type, path=''):
    if not isinstance(node, dict):
        return
    props = node.get('props', {})
    nid = node.get('id', '?')

    # Check icon prop on Icon and IconButton nodes
    ntype = node.get('type', '')
    if ntype in ('Icon', 'IconButton'):
        icon = props.get('icon', '')
        weight = props.get('weight', 'regular')
        if icon and not icon.startswith('{'):
            if weight == 'solid':
                if icon not in solid and icon not in regular:
                    hits.append(f'[{widget_type}] {nid}: icon \"{icon}\" not in SDUI icon map')
            else:
                if icon not in regular:
                    hits.append(f'[{widget_type}] {nid}: icon \"{icon}\" not in SDUI _iconMap')
                elif icon in fa6_solid_only and weight != 'solid':
                    hits.append(f'[{widget_type}] {nid}: icon \"{icon}\" is solid-only in FA6 Free but weight=\"{weight}\" — will render as question mark')

    # Check PopupMenu items
    for item in props.get('items', []):
        if isinstance(item, dict):
            icon = item.get('icon', '')
            if icon and not icon.startswith('{'):
                if icon not in regular:
                    hits.append(f'[{widget_type}] {nid} menu item: icon \"{icon}\" not in SDUI _iconMap')

    for child in node.get('children', []):
        check_icons(child, widget_type, f'{path}/{nid}')

for w in catalog.get('widgets', []):
    wt = w.get('metadata', {}).get('type', '?')
    check_icons(w.get('template', {}), wt)

for h in hits:
    print(h)
" 2>/dev/null)

  if [ -n "$ICON_ERRORS" ]; then
    echo "FAIL: Icon validation errors:"
    echo "$ICON_ERRORS"
    ERRORS=$((ERRORS + 1))
  fi
fi

# 6. Deprecated primitives (ReactTo, StateHolder, Interaction)
DEPRECATED=$(python3 -c "
import json
catalog = json.load(open('$CATALOG'))
deprecated = {'ReactTo', 'StateHolder', 'Interaction'}
hits = []
def check(node, wtype):
    if not isinstance(node, dict):
        return
    ntype = node.get('type', '')
    if ntype in deprecated:
        hits.append(f'[{wtype}] {node.get(\"id\",\"?\")}: uses removed primitive \"{ntype}\"')
    for child in node.get('children', []):
        check(child, wtype)
for w in catalog.get('widgets', []):
    wt = w.get('metadata', {}).get('type', '?')
    check(w.get('template', {}), wt)
for h in hits:
    print(h)
" 2>/dev/null)

if [ -n "$DEPRECATED" ]; then
  echo "FAIL: Deprecated primitives found:"
  echo "$DEPRECATED"
  ERRORS=$((ERRORS + 1))
fi

if [ $ERRORS -eq 0 ]; then
  echo "PASS: catalog.json validation passed"
fi

exit $ERRORS
