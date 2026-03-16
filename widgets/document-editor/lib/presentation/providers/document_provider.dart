import 'dart:async';

import 'package:flutter/material.dart';
import '../../di/service_locator.dart';
import '../../domain/models/content_state.dart';
import '../../domain/models/document_model.dart';
import '../../domain/models/edit_mode.dart';
import '../../domain/models/window_identity.dart';
import '../../domain/services/data_service.dart';
import '../../domain/services/event_bus.dart';
import '../../domain/services/event_payload.dart';
import '../../domain/services/window_channels.dart';

/// Manages document editor state: loading, editing, saving, mode switching.
///
/// Extends the window state pattern but owns document-specific state
/// (content, editMode, dirty tracking, save flow).
class DocumentProvider extends ChangeNotifier {
  final DataService _dataService = serviceLocator<DataService>();
  final EventBus _eventBus = serviceLocator<EventBus>();

  final WindowIdentity identity;
  final String windowId;

  // ── Window state ──

  ContentState _contentState = ContentState.loading;
  ContentState get contentState => _contentState;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  bool _focused = false;
  bool get focused => _focused;

  StreamSubscription<EventPayload>? _commandSubscription;

  // ── Document state ──

  DocumentModel? _document;
  DocumentModel? get document => _document;

  String _content = '';
  String get content => _content;

  String _originalContent = '';
  String get originalContent => _originalContent;

  EditMode _editMode = EditMode.rendered;
  EditMode get editMode => _editMode;

  bool get isDirty => _content != _originalContent;

  bool _isSaving = false;
  bool get isSaving => _isSaving;

  String? _saveError;
  String? get saveError => _saveError;

  // ── Text editing controller (shared between source and rendered) ──

  late TextEditingController textController;

  // ── Undo/Redo stack ──

  final List<String> _undoStack = [];
  final List<String> _redoStack = [];
  static const int _maxUndoDepth = 50;

  DocumentProvider({
    required this.identity,
    required this.windowId,
  }) {
    textController = TextEditingController();
    textController.addListener(_onTextChanged);

    _commandSubscription = _eventBus
        .subscribe(WindowChannels.commandChannel(windowId))
        .listen(_handleCommand);
  }

  // ── Inbound command handling ──

  void _handleCommand(EventPayload payload) {
    switch (payload.type) {
      case WindowChannels.typeFocus:
        _focused = true;
        notifyListeners();
        break;
      case WindowChannels.typeBlur:
        _focused = false;
        notifyListeners();
        break;
    }
  }

  // ── Outbound intents ──

  void _publishIntent(String type, [Map<String, dynamic> extra = const {}]) {
    _eventBus.publish(
      WindowChannels.windowIntent,
      EventPayload(
        type: type,
        sourceWidgetId: windowId,
        data: {'windowId': windowId, ...extra},
      ),
    );
  }

  void requestClose() => _publishIntent(WindowChannels.typeClose);

  // ── Document loading ──

  Future<void> loadDocument(String fileId, String projectId) async {
    _contentState = ContentState.loading;
    _errorMessage = null;
    _saveError = null;
    notifyListeners();

    try {
      _document = await _dataService.loadDocument(fileId, projectId);
      _content = _document!.content;
      _originalContent = _document!.content;
      textController.removeListener(_onTextChanged);
      textController.text = _content;
      textController.addListener(_onTextChanged);
      _undoStack.clear();
      _redoStack.clear();
      _undoStack.add(_content);

      identity.label = _document!.name;
      _publishIntent(WindowChannels.typeContentChanged, {
        'label': _document!.name,
      });

      _contentState = ContentState.active;
    } catch (e) {
      _errorMessage = e.toString();
      _contentState = ContentState.error;
    }
    notifyListeners();
  }

  // ── Text change tracking ──

  void _onTextChanged() {
    final newText = textController.text;
    if (newText != _content) {
      _content = newText;
      _saveError = null;

      // Push to undo stack.
      if (_undoStack.isEmpty || _undoStack.last != newText) {
        _undoStack.add(newText);
        if (_undoStack.length > _maxUndoDepth) {
          _undoStack.removeAt(0);
        }
        _redoStack.clear();
      }

      notifyListeners();
    }
  }

  /// Update content programmatically (e.g., from formatting actions).
  void updateContent(String newContent) {
    textController.removeListener(_onTextChanged);
    final selection = textController.selection;
    textController.text = newContent;
    // Try to restore selection.
    if (selection.isValid &&
        selection.start <= newContent.length &&
        selection.end <= newContent.length) {
      textController.selection = selection;
    }
    textController.addListener(_onTextChanged);
    _content = newContent;
    _saveError = null;

    if (_undoStack.isEmpty || _undoStack.last != newContent) {
      _undoStack.add(newContent);
      if (_undoStack.length > _maxUndoDepth) {
        _undoStack.removeAt(0);
      }
      _redoStack.clear();
    }

    notifyListeners();
  }

  // ── Mode switching ──

  void setEditMode(EditMode mode) {
    if (_editMode != mode) {
      _editMode = mode;
      notifyListeners();
    }
  }

  // ── Save ──

  Future<void> save() async {
    if (!isDirty || _isSaving || _document == null) return;

    _isSaving = true;
    _saveError = null;
    notifyListeners();

    try {
      final success =
          await _dataService.saveDocument(_document!.id, _content);
      if (success) {
        _originalContent = _content;
        _document = _document!.copyWith(content: _content);
      } else {
        _saveError = 'Save failed -- please try again';
      }
    } catch (e) {
      _saveError = 'Save failed: $e';
    }

    _isSaving = false;
    notifyListeners();
  }

  // ── Undo / Redo ──

  bool get canUndo => _undoStack.length > 1;
  bool get canRedo => _redoStack.isNotEmpty;

  void undo() {
    if (!canUndo) return;
    _redoStack.add(_undoStack.removeLast());
    final previous = _undoStack.last;
    textController.removeListener(_onTextChanged);
    textController.text = previous;
    textController.addListener(_onTextChanged);
    _content = previous;
    notifyListeners();
  }

  void redo() {
    if (!canRedo) return;
    final next = _redoStack.removeLast();
    _undoStack.add(next);
    textController.removeListener(_onTextChanged);
    textController.text = next;
    textController.addListener(_onTextChanged);
    _content = next;
    notifyListeners();
  }

  // ── Formatting helpers (for rendered mode) ──

  /// Wrap the current selection with prefix/suffix markdown.
  void wrapSelection(String prefix, String suffix) {
    final sel = textController.selection;
    if (!sel.isValid) return;
    final text = textController.text;
    final selected = sel.textInside(text);
    final newText =
        text.replaceRange(sel.start, sel.end, '$prefix$selected$suffix');
    final newCursorPos = sel.start + prefix.length + selected.length;
    updateContent(newText);
    textController.selection = TextSelection.collapsed(
      offset: newCursorPos,
    );
  }

  /// Prefix the current line with a string.
  void prefixLine(String prefix) {
    final sel = textController.selection;
    if (!sel.isValid) return;
    final text = textController.text;
    // Find start of the current line.
    int lineStart = sel.start;
    while (lineStart > 0 && text[lineStart - 1] != '\n') {
      lineStart--;
    }
    final newText = text.replaceRange(lineStart, lineStart, prefix);
    updateContent(newText);
    textController.selection = TextSelection.collapsed(
      offset: sel.start + prefix.length,
    );
  }

  /// Insert text at the current cursor position.
  void insertAtCursor(String insertion) {
    final sel = textController.selection;
    if (!sel.isValid) return;
    final text = textController.text;
    final newText = text.replaceRange(sel.start, sel.end, insertion);
    updateContent(newText);
    textController.selection = TextSelection.collapsed(
      offset: sel.start + insertion.length,
    );
  }

  /// Get the currently selected text.
  String getSelectedText() {
    final sel = textController.selection;
    if (!sel.isValid) return '';
    return sel.textInside(textController.text);
  }

  // ── Cursor-position formatting analysis (Section 5.8) ──

  /// Returns the current line (the line where the cursor sits).
  String _currentLine() {
    final sel = textController.selection;
    if (!sel.isValid) return '';
    final text = textController.text;
    int lineStart = sel.start;
    while (lineStart > 0 && text[lineStart - 1] != '\n') {
      lineStart--;
    }
    int lineEnd = sel.start;
    while (lineEnd < text.length && text[lineEnd] != '\n') {
      lineEnd++;
    }
    return text.substring(lineStart, lineEnd);
  }

  /// Whether the cursor is currently inside bold formatting.
  bool get isBoldActive {
    final sel = textController.selection;
    if (!sel.isValid) return false;
    final text = textController.text;
    final before = text.substring(0, sel.start);
    final after = text.substring(sel.start);
    return before.contains('**') &&
        after.contains('**') &&
        (before.split('**').length % 2 == 0);
  }

  /// Whether the cursor is currently inside italic formatting.
  bool get isItalicActive {
    final sel = textController.selection;
    if (!sel.isValid) return false;
    final text = textController.text;
    final before = text.substring(0, sel.start);
    final after = text.substring(sel.start);
    final singleBefore = before.replaceAll('**', '').split('*').length - 1;
    final singleAfter = after.replaceAll('**', '').split('*').length - 1;
    return singleBefore > 0 && singleAfter > 0 && singleBefore % 2 == 1;
  }

  /// Whether the cursor is currently inside strikethrough formatting.
  bool get isStrikethroughActive {
    final sel = textController.selection;
    if (!sel.isValid) return false;
    final text = textController.text;
    final before = text.substring(0, sel.start);
    final after = text.substring(sel.start);
    return before.contains('~~') &&
        after.contains('~~') &&
        (before.split('~~').length % 2 == 0);
  }

  /// Returns the heading level (1-3) if the cursor is on a heading line, else 0.
  int get activeHeadingLevel {
    final line = _currentLine().trimLeft();
    if (line.startsWith('### ')) return 3;
    if (line.startsWith('## ')) return 2;
    if (line.startsWith('# ')) return 1;
    return 0;
  }

  /// Whether the cursor is on a bullet list line.
  bool get isBulletListActive {
    final line = _currentLine().trimLeft();
    return line.startsWith('- ') || line.startsWith('* ');
  }

  /// Whether the cursor is on a numbered list line.
  bool get isNumberedListActive {
    final line = _currentLine().trimLeft();
    return RegExp(r'^\d+\.\s').hasMatch(line);
  }

  // ── Available documents (for DEV panel) ──

  List<String> get availableDocumentIds => _dataService.availableDocumentIds;

  @override
  void dispose() {
    _commandSubscription?.cancel();
    textController.removeListener(_onTextChanged);
    textController.dispose();
    super.dispose();
  }
}
