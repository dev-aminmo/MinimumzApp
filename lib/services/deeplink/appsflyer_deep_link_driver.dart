import 'package:minimumz/services/appsflyer_service.dart';

import 'deep_link_driver.dart';
import 'deep_link_target.dart';

/// AppsFlyer driver — adapts AppsFlyerService (SDK glue + OneLink generation +
/// deferred deep linking) to the DeepLinkDriver interface.
class AppsFlyerDeepLinkDriver implements DeepLinkDriver {
  final AppsFlyerService _sdk = AppsFlyerService.instance;

  @override
  void onIncomingLink(void Function(DeepLinkTarget) handler) =>
      _sdk.onIncomingTarget(handler);

  @override
  Future<void> init() => _sdk.init();

  @override
  Future<String?> createShareLink(DeepLinkTarget target) {
    switch (target.kind) {
      case DeepLinkKind.product:
        // Products don't have a dedicated generator; fall back to null (share
        // handled elsewhere) — kept for interface completeness.
        return Future.value(null);
      case DeepLinkKind.cart:
        return _sdk.generateCartShareLink(target.cartId ?? '');
      case DeepLinkKind.referral:
        return _sdk.generateReferralLink(target.referralCode ?? '');
      case DeepLinkKind.unknown:
        return Future.value(null);
    }
  }
}
