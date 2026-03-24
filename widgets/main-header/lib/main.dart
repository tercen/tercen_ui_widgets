import 'dart:convert';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:web/web.dart' as web;

import 'core/theme/app_theme.dart';
import 'di/service_locator.dart';
import 'domain/models/user_state.dart';
import 'implementations/services/tercen_event_bus.dart';
import 'implementations/services/tercen_header_data_service.dart';
import 'presentation/providers/header_state_provider.dart';
import 'presentation/providers/theme_provider.dart';
import 'presentation/screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  print('[main-header] waiting for init-context from orchestrator...');

  _listenForMessages((type, payload) async {
    if (type != 'init-context') {
      print('[main-header] ignoring message type=$type (waiting for init-context)');
      return;
    }

    print('[main-header] received init-context, payload keys: ${payload.keys.toList()}');

    try {
      // --- Extract required fields from init-context ---
      final displayName = payload['displayName'] as String?;
      final identityString = payload['identityString'] as String?;
      final isAdmin = payload['isAdmin'] as bool?;
      final llmConnected = payload['llmConnected'] as bool?;

      if (displayName == null) {
        throw StateError('init-context missing required field: displayName');
      }
      if (identityString == null) {
        throw StateError('init-context missing required field: identityString');
      }
      if (isAdmin == null) {
        throw StateError('init-context missing required field: isAdmin');
      }
      if (llmConnected == null) {
        throw StateError('init-context missing required field: llmConnected');
      }

      print('[main-header] user=$displayName, identity=$identityString, admin=$isAdmin, llm=$llmConnected');

      // --- Build real services ---
      final eventBus = TercenEventBus();

      final userState = UserState(
        displayName: displayName,
        identityString: identityString,
        isAdmin: isAdmin,
      );

      final dataService = TercenHeaderDataService(
        userState: userState,
        llmConnected: llmConnected,
      );

      setupServiceLocator(
        eventBus: eventBus,
        dataService: dataService,
      );

      print('[main-header] services registered, launching app');

      final prefs = await SharedPreferences.getInstance();
      runApp(MainHeaderApp(prefs: prefs));

      // --- Signal readiness to orchestrator ---
      _postToOrchestrator('app-ready', {});
      print('[main-header] app-ready sent to orchestrator');
    } catch (e, stack) {
      print('[main-header] ERROR during init: $e');
      print('[main-header] stack: $stack');
      runApp(_buildErrorApp('Main header init failed: $e'));
      rethrow;
    }
  });
}

// --- postMessage helpers ---

void _listenForMessages(
    void Function(String type, Map<String, dynamic> payload) onMessage) {
  web.window.addEventListener(
      'message',
      (web.Event event) {
        try {
          final msgEvent = event as web.MessageEvent;
          final data = msgEvent.data;
          if (data == null) return;

          final jsonObj = web.window['JSON']! as JSObject;
          final jsonStr =
              jsonObj.callMethod('stringify'.toJS, data) as JSString;
          final map = json.decode(jsonStr.toDart) as Map<String, dynamic>;

          final type = map['type'] as String?;
          final source = map['source'] as String?;
          final payload = map['payload'] as Map<String, dynamic>? ?? {};

          if (type == null) {
            print('[main-header] WARNING: received message with no type field: $map');
            return;
          }

          print('[main-header] postMessage received: type=$type source=$source');
          onMessage(type, payload);
        } catch (e) {
          print('[main-header] WARNING: failed to parse postMessage: $e');
        }
      }.toJS);
}

void _postToOrchestrator(String type, Map<String, dynamic> payload) {
  final message = {
    'type': type,
    'source': 'main-header',
    'target': 'orchestrator',
    'payload': payload,
  };
  print('[main-header] posting to orchestrator: type=$type');
  web.window.parent?.postMessage(message.jsify(), '*'.toJS);
}

// --- Error app ---

Widget _buildErrorApp(String message) {
  return MaterialApp(
    home: Scaffold(
      backgroundColor: const Color(0xFFFFEBEE),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            message,
            style: const TextStyle(
              color: Color(0xFFB71C1C),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    ),
  );
}

// --- App widget ---

class MainHeaderApp extends StatelessWidget {
  final SharedPreferences prefs;

  const MainHeaderApp({super.key, required this.prefs});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider(prefs)),
        ChangeNotifierProvider(create: (_) => HeaderStateProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) {
          return MaterialApp(
            title: 'Header Widget',
            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            themeMode: themeProvider.themeMode,
            debugShowCheckedModeBanner: false,
            home: const HomeScreen(),
          );
        },
      ),
    );
  }
}
