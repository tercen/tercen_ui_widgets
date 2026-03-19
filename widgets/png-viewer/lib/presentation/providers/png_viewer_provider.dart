import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import '../../di/service_locator.dart';
import '../../domain/models/annotation_model.dart';
import '../../domain/models/content_state.dart';
import '../../domain/models/image_model.dart';
import '../../domain/services/data_service.dart';
import '../../domain/services/event_payload.dart';
import '../../domain/services/window_channels.dart';
import 'window_state_provider.dart';

/// Provider for the PNG Viewer window.
///
/// Extends WindowStateProvider to inherit content state management,
/// EventBus command handling (focus/blur), and window intent publishing.
/// Adds domain-specific state: image data, drawing tools, annotations, zoom/pan.
class PngViewerProvider extends WindowStateProvider {
  final DataService _dataService = serviceLocator<DataService>();

  // -- Image data --

  ImageModel? _image;
  ImageModel? get image => _image;

  // -- Drawing tool --

  DrawingTool? _activeTool;
  DrawingTool? get activeTool => _activeTool;

  // -- Annotations --

  final List<AnnotationModel> _annotations = [];
  List<AnnotationModel> get annotations => List.unmodifiable(_annotations);

  // -- In-progress annotation --

  List<ImagePoint>? _inProgressPoints;
  List<ImagePoint>? get inProgressPoints => _inProgressPoints;

  // -- Zoom and pan --

  double _zoomLevel = 1.0;
  double get zoomLevel => _zoomLevel;

  Offset _panOffset = Offset.zero;
  Offset get panOffset => _panOffset;

  // -- Last load command (for retry) --

  String? _lastResourceType;
  String? _lastResourceId;

  StreamSubscription<EventPayload>? _loadImageSubscription;

  PngViewerProvider({
    required super.identity,
    required super.windowId,
  }) {
    // Subscribe to load image commands.
    _loadImageSubscription = eventBus
        .subscribe('visualization.$windowId.loadImage')
        .listen(_handleLoadImage);
  }

  // -- Inbound load image handling --

  void _handleLoadImage(EventPayload payload) {
    if (payload.type == 'loadImage') {
      final resourceType = payload.data['resourceType'] as String? ?? '';
      final resourceId = payload.data['resourceId'] as String? ?? '';
      loadImage(resourceType: resourceType, resourceId: resourceId);
    }
  }

  // -- Image loading --

  Future<void> loadImage({
    required String resourceType,
    required String resourceId,
  }) async {
    _lastResourceType = resourceType;
    _lastResourceId = resourceId;
    setContentState(ContentState.loading);
    setErrorMessage(null);
    notifyListeners();

    try {
      final img = await _dataService.fetchImage(
        resourceType: resourceType,
        resourceId: resourceId,
      );
      _image = img;
      _annotations.clear();
      _activeTool = null;
      _inProgressPoints = null;
      _zoomLevel = 1.0;
      _panOffset = Offset.zero;
      setContentState(ContentState.active);

      // Update window label to filename.
      identity.label = img.name;
      publishIntent(WindowChannels.typeContentChanged, {'label': img.name});
    } catch (e) {
      setErrorMessage(e.toString());
      setContentState(ContentState.error);
    }
    notifyListeners();
  }

  /// Override loadData for WindowBody error-retry compatibility.
  @override
  Future<void> loadData() async {
    retryLoad();
  }

  /// Retry the last load image command.
  void retryLoad() {
    if (_lastResourceType != null && _lastResourceId != null) {
      loadImage(
        resourceType: _lastResourceType!,
        resourceId: _lastResourceId!,
      );
    }
  }

  // -- Drawing tool management --

  void setActiveTool(DrawingTool? tool) {
    if (_activeTool == tool) {
      // Toggle off.
      _activeTool = null;
    } else {
      _activeTool = tool;
    }
    // Clear any in-progress annotation when switching tools.
    _inProgressPoints = null;
    notifyListeners();
  }

  // -- Annotation management --

  void addAnnotation(AnnotationModel annotation) {
    _annotations.add(annotation);
    _inProgressPoints = null;
    notifyListeners();
  }

  void setInProgressPoints(List<ImagePoint>? points) {
    _inProgressPoints = points;
    notifyListeners();
  }

  void clearAllAnnotations() {
    _annotations.clear();
    _inProgressPoints = null;
    notifyListeners();
  }

  bool get hasAnnotations => _annotations.isNotEmpty;

  // -- Zoom and pan --

  void setZoomLevel(double zoom) {
    _zoomLevel = zoom.clamp(0.1, 10.0);
    notifyListeners();
  }

  void zoomIn() {
    setZoomLevel(_zoomLevel * 1.25);
  }

  void zoomOut() {
    setZoomLevel(_zoomLevel / 1.25);
  }

  void fitToWindow(Size viewportSize) {
    if (_image == null) return;
    final scaleX = viewportSize.width / _image!.width;
    final scaleY = viewportSize.height / _image!.height;
    _zoomLevel = scaleX < scaleY ? scaleX : scaleY;
    if (_zoomLevel > 1.0) _zoomLevel = 1.0; // Don't upscale beyond native.
    _panOffset = Offset.zero;
    notifyListeners();
  }

  void setPanOffset(Offset offset) {
    _panOffset = offset;
    notifyListeners();
  }

  // -- Send to Chat --

  void sendToChat() {
    if (_image == null || _annotations.isEmpty) return;

    final annotatedImageBase64 = base64Encode(_image!.imageBytes);

    final payload = {
      'annotatedImageBase64':
          '${annotatedImageBase64.substring(0, 80)}... [truncated]',
      'annotations': _annotations.map((a) => a.toJson()).toList(),
      'sourceImage': {
        'resourceId': _image!.resourceId,
        'resourceType': _image!.resourceType,
      },
    };

    // Log to console (mock behaviour).
    debugPrint('=== Send to Chat ===');
    debugPrint(
        'annotatedImageBase64: ${annotatedImageBase64.substring(0, 80)}... [${annotatedImageBase64.length} chars total]');
    debugPrint(
        'annotations: ${const JsonEncoder.withIndent('  ').convert(_annotations.map((a) => a.toJson()).toList())}');
    debugPrint(
        'sourceImage: {resourceId: ${_image!.resourceId}, resourceType: ${_image!.resourceType}}');
    debugPrint('====================');

    // Publish on EventBus.
    eventBus.publish(
      'visualization.annotations.send',
      EventPayload(
        type: 'annotationBundle',
        sourceWidgetId: windowId,
        data: payload,
      ),
    );
  }

  @override
  void dispose() {
    _loadImageSubscription?.cancel();
    super.dispose();
  }
}
