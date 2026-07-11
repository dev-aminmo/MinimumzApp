import 'dart:async';
import 'dart:developer';

import 'package:appsflyer_sdk/appsflyer_sdk.dart';
import 'package:minimumz/services/deeplink/deep_link_target.dart';

/// AppsFlyer attribution + OneLink deep linking.
///
/// Handles two deep-link actions, both via a OneLink `deep_link_value`:
///   • product → opens the product details page
///       deep_link_value = "product", product_id = "<id>"
///       (also accepts the storefront CTA scheme: cta_type=product & cta_id=<id>)
///   • cart    → copies a shared cart's items into the user's own cart
///       deep_link_value = "cart", cart_id = "<id>"
///
/// Routing reuses [DataStore] + the global [AppRouter] / [CartBloc], so it works
/// from the SDK callback without a BuildContext.
class AppsFlyerService {
  AppsFlyerService._();
  static final AppsFlyerService instance = AppsFlyerService._();

  // TODO(config): fill these from the AppsFlyer dashboard before release.
  //  - afDevKey: App settings → Dev key
  //  - iosAppId: numeric App Store ID (e.g. "123456789"), no "id" prefix
  //  - oneLinkTemplateId: OneLink → your template's short ID (e.g. "abc1")
  static const String _afDevKey = 'YOUR_APPSFLYER_DEV_KEY';
  static const String _iosAppId = 'YOUR_IOS_APP_STORE_ID';
  static const String _oneLinkTemplateId = 'YOUR_ONELINK_TEMPLATE_ID';

  AppsflyerSdk? _sdk;
  bool _started = false;

  Future<void> init() async {
    if (_started) return;
    _started = true;

    final options = AppsFlyerOptions(
      afDevKey: _afDevKey,
      appId: _iosAppId, // iOS only; ignored on Android
      showDebug: true,
      timeToWaitForATTUserAuthorization: 15,
    );

    final sdk = AppsflyerSdk(options);
    _sdk = sdk;
    sdk.onDeepLinking(_onDeepLinking);

    try {
      await sdk.initSdk(
        registerConversionDataCallback: true,
        registerOnAppOpenAttributionCallback: true,
        registerOnDeepLinkingCallback: true,
      );
      // Needed by generateInviteLink to build OneLinks (cart sharing).
      sdk.setAppInviteOneLinkID(_oneLinkTemplateId, (_) {});
    } catch (e, st) {
      log('AppsFlyer initSdk failed: $e', stackTrace: st);
    }
  }

  // ── Deep link handling ──────────────────────────────────────────────────────

  void Function(DeepLinkTarget)? _onTarget;

  /// Register the handler that receives incoming links as driver-agnostic
  /// targets. Routing (open product / copy cart / capture referral) lives in
  /// DeepLinkService, so this service is only SDK glue + link generation.
  void onIncomingTarget(void Function(DeepLinkTarget) handler) => _onTarget = handler;

  void _onDeepLinking(DeepLinkResult result) {
    if (result.status != Status.FOUND) {
      if (result.status == Status.ERROR) {
        log('AppsFlyer deep link error: ${result.error}');
      }
      return;
    }

    final dl = result.deepLink;
    final value = dl?.deepLinkValue;
    DeepLinkTarget? target;

    final referralCode = dl?.getStringValue('referral_code');
    if (value == 'referral' && referralCode != null && referralCode.isNotEmpty) {
      target = DeepLinkTarget.referral(referralCode);
    }

    final cartId = dl?.getStringValue('cart_id');
    if (target == null && value == 'cart' && cartId != null && cartId.isNotEmpty) {
      target = DeepLinkTarget.cart(cartId);
    }

    final productId = dl?.getStringValue('product_id') ?? dl?.getStringValue('cta_id');
    final marker = value ?? dl?.getStringValue('cta_type');
    if (target == null &&
        productId != null &&
        productId.isNotEmpty &&
        (marker == 'product' || dl?.getStringValue('product_id') != null)) {
      target = DeepLinkTarget.product(productId);
    }

    if (target != null) _onTarget?.call(target);
  }

  // ── Link generation (cart sharing) ──────────────────────────────────────────

  /// Build a OneLink that, when opened, copies this cart into the recipient's
  /// cart. Returns null if the SDK isn't ready or generation fails/times out.
  Future<String?> generateCartShareLink(String cartId) async {
    final sdk = _sdk;
    if (sdk == null) return null;

    final completer = Completer<String?>();
    final params = AppsFlyerInviteLinkParams(
      campaign: 'cart_share',
      channel: 'app',
      customParams: {'deep_link_value': 'cart', 'cart_id': cartId},
    );

    sdk.generateInviteLink(
      params,
      (dynamic data) {
        if (!completer.isCompleted) completer.complete(_extractUrl(data));
      },
      (dynamic error) {
        if (!completer.isCompleted) completer.complete(null);
      },
    );

    return completer.future
        .timeout(const Duration(seconds: 10), onTimeout: () => null);
  }

  /// Build a OneLink carrying a referral code. When a friend opens it (and
  /// installs), the code is captured (deferred deep link) and applied at signup.
  Future<String?> generateReferralLink(String code) async {
    final sdk = _sdk;
    if (sdk == null) return null;

    final completer = Completer<String?>();
    final params = AppsFlyerInviteLinkParams(
      campaign: 'referral',
      channel: 'app',
      customParams: {'deep_link_value': 'referral', 'referral_code': code},
    );

    sdk.generateInviteLink(
      params,
      (dynamic data) {
        if (!completer.isCompleted) completer.complete(_extractUrl(data));
      },
      (dynamic error) {
        if (!completer.isCompleted) completer.complete(null);
      },
    );

    return completer.future
        .timeout(const Duration(seconds: 10), onTimeout: () => null);
  }

  /// The generate-link callback shape varies by platform/version; pull the URL
  /// out defensively.
  String? _extractUrl(dynamic data) {
    if (data is String) {
      final m = RegExp(r'https?://[^\s"]+').firstMatch(data);
      return m?.group(0) ?? (data.startsWith('http') ? data : null);
    }
    if (data is Map) {
      final payload = data['payload'] is Map ? data['payload'] as Map : data;
      final url = payload['userInviteURL'] ?? payload['link'] ?? payload['url'];
      if (url is String && url.startsWith('http')) return url;
      final m = RegExp(r'https?://[^\s"]+').firstMatch(data.toString());
      return m?.group(0);
    }
    return null;
  }
}
