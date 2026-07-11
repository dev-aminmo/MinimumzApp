import 'dart:developer';

import 'package:app_links/app_links.dart';

import 'deep_link_driver.dart';
import 'deep_link_target.dart';

/// Native deep-link driver: builds links against your own domain and receives
/// incoming App Links / Universal Links via the `app_links` package. No third
/// party. Requires the domain to be registered as an App Link (Android
/// assetlinks) / Universal Link (iOS AASA) — the same capability we set up for
/// OneLink, just pointed at your domain.
///
/// Link formats (both are parsed inbound; outbound uses the custom scheme):
///   Custom scheme : minimumz://product/<id>  minimumz://cart/<id>  minimumz://r/<code>
///   Web/App Link  : <base>/link/product/<id>  /link/cart/<id>  /link/r/<code>
///
/// The custom scheme opens the app from a tap without any domain/HTTPS/asset
/// verification — ideal for dev + installed-app sharing. The /link/... web form
/// stays supported so a real HTTPS domain (App Links / Universal Links) can be
/// dropped in later with zero code change.
///
/// Note: native cannot do DEFERRED deep linking — a referral opened before the
/// app is installed won't carry the code across the install. Installed-app links
/// work fully. (Switch to the AppsFlyer driver if deferred linking is needed.)
class NativeDeepLinkDriver implements DeepLinkDriver {
  NativeDeepLinkDriver(this.baseUrl);

  /// Custom URL scheme registered in AndroidManifest + iOS Info.plist.
  static const String scheme = 'minimumz';

  final String baseUrl;
  final AppLinks _appLinks = AppLinks();
  void Function(DeepLinkTarget)? _handler;

  @override
  void onIncomingLink(void Function(DeepLinkTarget) handler) => _handler = handler;

  @override
  Future<void> init() async {
    try {
      final initial = await _appLinks.getInitialLink();
      if (initial != null) _dispatch(initial);
    } catch (e) {
      log('NativeDeepLink initial link failed: $e');
    }
    _appLinks.uriLinkStream.listen(_dispatch, onError: (e) {
      log('NativeDeepLink stream error: $e');
    });
  }

  @override
  Future<String?> createShareLink(DeepLinkTarget target) async {
    switch (target.kind) {
      case DeepLinkKind.product:
        return target.productId != null ? '$scheme://product/${target.productId}' : null;
      case DeepLinkKind.cart:
        return target.cartId != null ? '$scheme://cart/${target.cartId}' : null;
      case DeepLinkKind.referral:
        return target.referralCode != null ? '$scheme://r/${target.referralCode}' : null;
      case DeepLinkKind.unknown:
        return null;
    }
  }

  void _dispatch(Uri uri) {
    final target = _parse(uri);
    if (target != null && _handler != null) _handler!(target);
  }

  /// Parse either the custom scheme (`minimumz://<type>/<value>`) or the web
  /// form (`<base>/link/<type>/<value>`).
  DeepLinkTarget? _parse(Uri uri) {
    // Custom scheme: type is the URI host, value is the first path segment.
    if (uri.scheme == scheme) {
      final segs = uri.pathSegments.where((s) => s.isNotEmpty).toList();
      return _target(uri.host, segs.isNotEmpty ? segs.first : null);
    }

    // Web/App Link: /link/<type>/<value>.
    final segs = uri.pathSegments.where((s) => s.isNotEmpty).toList();
    if (segs.length >= 2 && segs.first == 'link') {
      return _target(segs[1], segs.length > 2 ? segs[2] : null);
    }
    return null;
  }

  DeepLinkTarget? _target(String type, String? value) {
    if (value == null || value.isEmpty) return null;
    switch (type) {
      case 'product':
        return DeepLinkTarget.product(value);
      case 'cart':
        return DeepLinkTarget.cart(value);
      case 'r':
      case 'referral':
        return DeepLinkTarget.referral(value);
      default:
        return null;
    }
  }
}
