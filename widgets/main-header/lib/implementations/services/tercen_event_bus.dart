import 'dart:async';
import 'dart:convert';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:web/web.dart' as web;

import '../../domain/services/event_bus.dart';

/// Real EventBus that communicates via postMessage with the orchestrator.
///
/// - publish() sends envelopes to window.parent
/// - subscribe() listens to window 'message' events, filtered by channel
class TercenEventBus implements EventBus {
  static const String _source = 'main-header';

  @override
  void publish(
      String channel, String intentType, Map<String, dynamic> payload) {
    final envelope = {
      'type': intentType,
      'source': _source,
      'target': 'orchestrator',
      'payload': {
        'channel': channel,
        ...payload,
      },
    };

    print(
        '[TercenEventBus] publish: channel=$channel type=$intentType payload=$payload');

    try {
      web.window.parent?.postMessage(envelope.jsify(), '*'.toJS);
      print('[TercenEventBus] postMessage sent to parent');
    } catch (e) {
      print('[TercenEventBus] ERROR sending postMessage: $e');
      rethrow;
    }
  }

  @override
  Stream<Map<String, dynamic>> subscribe(String channel) {
    print('[TercenEventBus] subscribe: channel=$channel');

    final controller = StreamController<Map<String, dynamic>>.broadcast();

    web.window.addEventListener(
        'message',
        (web.Event event) {
          try {
            final msgEvent = event as web.MessageEvent;
            final data = msgEvent.data;
            if (data == null) return;

            // Convert JS object to Dart map
            final jsonObj = web.window['JSON']! as JSObject;
            final jsonStr =
                jsonObj.callMethod('stringify'.toJS, data) as JSString;
            final map =
                json.decode(jsonStr.toDart) as Map<String, dynamic>;

            final type = map['type'] as String?;
            final msgPayload =
                map['payload'] as Map<String, dynamic>? ?? {};
            final msgChannel = msgPayload['channel'] as String?;

            if (type == null) {
              print(
                  '[TercenEventBus] WARNING: received message with no type: $map');
              return;
            }

            print(
                '[TercenEventBus] received: type=$type channel=$msgChannel payload=$msgPayload');

            // Filter by channel
            if (msgChannel == channel) {
              controller.add({
                'type': type,
                ...msgPayload,
              });
            }
          } catch (e) {
            print(
                '[TercenEventBus] WARNING: failed to parse message: $e');
          }
        }.toJS);

    return controller.stream;
  }
}
