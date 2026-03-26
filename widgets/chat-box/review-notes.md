# ChatBox SDUI Deployment Review

Date: 2026-03-25
Scope: Files reviewed for hardcoded values, missing mappings, channel consistency,
scope variable correctness, and deployment-blocking issues.

---

## Files Reviewed

- `/home/martin/tercen/sdui/pubspec.yaml`
- `/home/martin/tercen/sdui/lib/src/registry/builtin_widgets.dart`
- `/home/martin/tercen/sdui/lib/src/registry/behavior_widgets.dart`
- `/home/martin/tercen/sdui/lib/src/renderer/sdui_render_context.dart`
- `/home/martin/tercen/tercen_ui_orchestrator/lib/main.dart`
- `/home/martin/tercen/tercen_ui_widgets/catalog.json`

---

## Issues Found

### 1. BLOCKING — Four icon names in the ChatBox template are not in `_iconMap`

The `Icon` primitive falls back to `FontAwesomeIcons.circleQuestion` (a visible
question-mark icon) when a name is not found. This means missing icon names do not
crash but produce the wrong icon silently.

| Template location | Icon name used | Present in `_iconMap`? |
|---|---|---|
| `{{widgetId}}-empty-icon` (empty state) | `comments` | No |
| `{{widgetId}}-ic-user` (user role badge) | `user` | No — map has `person` not `user` |
| `{{widgetId}}-ic-tool` (tool role badge) | `wrench` | No — map has `build` (screwdriverWrench) not `wrench` |
| `{{widgetId}}-ic-error` (error role badge) | `circle-exclamation` | No — map has `error` not the hyphenated FA6 key |

The send button uses `paper-plane-top` which is also absent from `_iconMap`; the
registered key is `send` (mapped to `FontAwesomeIcons.paperPlane`). All five icons
will silently render as a question mark.

Fix options (pick one per icon):
- Add the missing keys to `_iconMap` in `builtin_widgets.dart`, or
- Update the catalog.json template to use the existing registered keys:
  `comments` -> `chat`, `user` -> `person`, `wrench` -> `build`,
  `circle-exclamation` -> `error`, `paper-plane-top` -> `send`.

### 2. BLOCKING — `inputId` forward-reference: `{{widgetId}}` may not resolve inside a prop

In the ChatBox template the `ChatStream` node carries:

```json
"inputId": "{{widgetId}}-input"
```

`{{widgetId}}` is a catalog-level variable injected by the window manager before
rendering. If the template resolver resolves props at build time (before the subtree
is fully walked), the `inputId` value that `ChatStream` receives at `initState` is the
resolved string `"<actualId>-input"` and matches the TextField node id
`"{{widgetId}}-input"` (also resolved). This is correct **only if** both resolutions
happen in the same pass with the same `widgetId` value.

However, `ChatStream._subscribeControls()` subscribes to
`input.$inputId.changed` and `input.$inputId.submitted` during `initState`.
If `widgetId` is not yet in the template resolver's scope when the `ChatStream`
node is instantiated (e.g., it is injected after the render tree is built), the
`inputId` will be the literal string `"{{widgetId}}-input"` and the EventBus
channel subscriptions will never fire.

Verify that `widgetId` is set in the resolver **before** the root widget is built,
not lazily. If this is not guaranteed, the `inputId` should be an explicit static
string rather than a template binding.

### 3. BLOCKING — `item.isStreaming` rendered from inside `ForEach` scope

The streaming indicator conditional:

```json
{ "visible": "{{item.isStreaming}}" }
```

`ForEach` exposes `{{item}}` as the current element. `_makeMessage` in
`_ChatStreamWidgetState` sets `isStreaming` as a top-level key on the message map.
The binding `{{item.isStreaming}}` therefore correctly resolves via JSON-path
traversal — **provided** the template resolver handles dot-notation into a Map
that is itself a scope variable. Confirm the resolver handles `item.isStreaming`
where `item` is a `Map<String, dynamic>`. If the resolver only supports a single
level of key lookup (i.e., it looks up `"item.isStreaming"` as a literal key rather
than traversing `item` then `isStreaming`), this condition will never be true and
the streaming indicator will never show.

### 4. MODERATE — Hardcoded hex colors and literal `grey` in catalog.json

Two templates in `catalog.json` (not the ChatBox widget itself but co-resident in
the same file) use hardcoded color values:

- Line 912: `"color": "#1E1E1E"` (AuditTrail toolbar background)
- Line 922: `"color": "#0D9488"` (AuditTrail title text)
- Lines 928, 944: `"color": "grey"` (AuditTrail scope label and empty text)

The `color` prop for `Container` and `Text` primitives is expected to be a semantic
token name (e.g., `surfaceContainerHigh`, `onSurfaceMuted`) that is resolved through
`SduiTheme`. Hex strings and `"grey"` will not resolve to a theme color; the
primitives fall back to the default color or render incorrectly in dark mode.

These are in the AuditTrail widget, not ChatBox, but they are present in the same
catalog file and will affect that widget's appearance.

### 5. MODERATE — `navigateHome`, `saveLayout`, `connectLlm`, `taskManager`, `signOut` intents are stubs

In `main.dart` lines 130-140, five `header.intent` cases log
`"not yet implemented"` and do nothing. These are not ChatBox-specific but they
represent silent no-ops for header actions that users may invoke. If the UI exposes
these actions they should either be implemented or the corresponding menu items
should be hidden/disabled.

### 6. MODERATE — `tool_start` message text uses a Unicode wrench emoji literal

In `behavior_widgets.dart` line 1238:

```dart
text: '\u{1F527} ${msg['toolName']}...',
```

The ChatBox SDUI template renders tool messages with a `Text` primitive, which will
display the raw Unicode wrench emoji. This is not incorrect, but it duplicates the
wrench icon that the template already renders via the `Icon` node for `isTool`. The
result is that tool messages display both the icon (from the `Conditional` block)
and an inline emoji. Whether this is intentional should be confirmed.

### 7. LOW — `flutter_markdown` version pinned to `^0.7.6` but package ecosystem moves fast

`pubspec.yaml` pins `flutter_markdown: ^0.7.6` and `markdown: ^7.2.2`. These are
reasonable constraints but `flutter_markdown 0.7.x` requires Flutter SDK
`>=3.22.0`. Verify the deployment build environment meets this requirement.
No hardcoded fallback was found in `_buildMarkdown` — it renders correctly or throws,
which is the right behavior.

### 8. LOW — `chatStreamProvider` silently no-ops when null

`_ChatStreamWidget._connectChat()` does:

```dart
final provider = widget.context.chatStreamProvider;
if (provider == null) {
  _connected = false;
  return;
}
```

If the orchestrator fails to wire `chatStreamProvider` (e.g., due to a startup
race or a future refactor), the ChatBox renders its empty-state UI permanently
with no error. This is a silent degradation. An ErrorReporter warning on null
provider would make the failure visible.

### 9. LOW — `ChatStream` scope does not expose `isConnected` with a consistent name

The `ChatStream` widget metadata documents it exposes `{{connected}}` (bool).
The `build()` method sets:

```dart
'connected': _connected,
```

However, `_connected` is only set once at `initState` from `provider.isConnected()`
and is never updated if the WebSocket reconnects or disconnects after initialisation.
If the connection drops and recovers, `{{connected}}` stays stale. This is a
correctness issue if the template uses `{{connected}}` to show a connection status
badge.

### 10. INFO — Dead `chat.message.sent` EventBus channel in metadata

The `ChatBox` metadata declares `"chat.message.sent"` as an emitted event, but
`_ChatStreamWidgetState` never publishes to `chat.message.sent`. It only reads from
the WebSocket stream and publishes to `_clearChannel` after sending. The declared
emitted event is unused. Remove it from the metadata or implement the publish.

---

## Channel Consistency Summary

| Channel | Producer | Consumer | Status |
|---|---|---|---|
| `chat.send` | IconButton `channel` prop | `ChatStream.sendChannel` | Consistent |
| `chat.inputCleared` | `ChatStream._clearChannel` publish | TextField `clearOn` prop | Consistent |
| `input.{{widgetId}}-input.changed` | TextField (auto-publish) | `ChatStream._changeSub` | Consistent if `widgetId` resolves (see issue 2) |
| `input.{{widgetId}}-input.submitted` | TextField (auto-publish) | `ChatStream._submitSub` | Consistent if `widgetId` resolves (see issue 2) |

---

## What Was Checked and Found Clean

- `pubspec.yaml`: `font_awesome_flutter ^10.6.0` and `flutter_markdown ^0.7.6`
  are present. No local path dependencies.
- `sdui_render_context.dart`: `ChatStreamProvider` typedef is correct and
  `chatStreamProvider` is nullable — orchestrator wires it in `initState`.
- `main.dart` wiring: `_client.chatMessages`, `_client.sendChat`, and
  `_client.state` are all real OrchestratorClient members, not mocks.
- `ChatStream` scope variables `{{messages}}`, `{{isStreaming}}`, `{{connected}}`,
  `{{hasMessages}}` all match what `build()` populates.
- `Markdown` primitive: fully theme-token-driven, no hardcoded colors.
- `TextField.clearOn` is documented and registered. `chat.inputCleared` matches.
- `ChatStream` metadata `sendChannel` default and `clearChannel` default match
  the literal values in the template props.
- `home` layout entry for `ChatBox` uses `"size": "column"` and `"align": "right"`
  which matches the window manager's expected size/align vocabulary.
- No TODO, FIXME, or HACK comments in any of the reviewed files.
- No mock services or placeholder service callers are wired in the production path.
