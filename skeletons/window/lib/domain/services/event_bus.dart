/// Abstract event bus interface for window–Frame communication.
///
/// The window emits intents and receives messages through this interface.
/// The skeleton defines the contract only — implementation is provided
/// at Frame integration time.
///
/// Outbound (window emits):
///   - close: window requests to be closed
///   - maximize / restore: window requests resize
///   - openResource: user clicked something that should open elsewhere
///   - contentChanged: window's label has changed
///
/// Inbound (window receives):
///   - themeChanged: light/dark mode changed
///   - focus: Frame is giving this window focus
///   - blur: Frame is removing focus
abstract class EventBus {
  /// Emit an intent from this window to the Frame.
  void emit(String intent, {Map<String, dynamic>? payload});

  /// Subscribe to messages from the Frame.
  /// Returns a dispose function to unsubscribe.
  Function() on(String message, void Function(Map<String, dynamic>?) handler);
}
