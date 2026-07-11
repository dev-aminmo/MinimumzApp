import 'deep_link_target.dart';

/// Strategy interface for deep linking. Implementations:
///   NativeDeepLinkDriver    — your own domain (App/Universal Links) + server config
///   AppsFlyerDeepLinkDriver — AppsFlyer OneLink + deferred deep linking
///
/// High-level code (DeepLinkService) depends on this abstraction only, so a
/// driver can be swapped via config without touching any caller (DIP / OCP).
abstract class DeepLinkDriver {
  /// Start listening for incoming links (and fire the handler for a cold-start link).
  Future<void> init();

  /// Build a shareable URL for the given target, or null if it can't be built.
  Future<String?> createShareLink(DeepLinkTarget target);

  /// Register the handler invoked when an incoming link is received.
  void onIncomingLink(void Function(DeepLinkTarget) handler);
}
