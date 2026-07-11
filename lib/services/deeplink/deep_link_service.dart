import 'dart:developer';

import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:minimumz/data/data.dart';
import 'package:minimumz/di/di.dart';
import 'package:minimumz/domain/repository/preference_repository.dart';
import 'package:minimumz/presentation/routes/app_router.dart';
import 'package:minimumz/presentation/screens/cart/bloc/cart/cart_bloc.dart';

import 'appsflyer_deep_link_driver.dart';
import 'deep_link_driver.dart';
import 'deep_link_target.dart';
import 'native_deep_link_driver.dart';

/// Which deep-link driver to use. App-side config — flip + rebuild to switch.
/// Can later be moved to a server setting without touching callers.
enum DeepLinkDriverKind { native, appsflyer }

class DeepLinkConfig {
  // ── Flip the driver here ──────────────────────────────────────────────────
  static const DeepLinkDriverKind driver = DeepLinkDriverKind.native;

  /// Native links use the SAME host as the API (from module.dart's baseUrl),
  /// so the deep-link domain always tracks the API config. Derived as the
  /// origin (scheme://host[:port]) of DataStore.baseUrl, minus any /api path.
  static String nativeBaseUrl() {
    final uri = Uri.tryParse(getIt<DataStore>().baseUrl);
    if (uri == null || !uri.hasScheme) return 'https://link.minimumz.com';
    final port = uri.hasPort ? ':${uri.port}' : '';
    return '${uri.scheme}://${uri.host}$port';
  }
}

/// The single entry point the app uses for deep links. Depends on the
/// DeepLinkDriver abstraction — swapping drivers changes nothing here or in any
/// caller (Dependency Inversion / Open-Closed).
class DeepLinkService {
  DeepLinkService._();
  static final DeepLinkService instance = DeepLinkService._();

  late final DeepLinkDriver _driver = _makeDriver();

  DeepLinkDriver _makeDriver() {
    switch (DeepLinkConfig.driver) {
      case DeepLinkDriverKind.appsflyer:
        return AppsFlyerDeepLinkDriver();
      case DeepLinkDriverKind.native:
        return NativeDeepLinkDriver(DeepLinkConfig.nativeBaseUrl());
    }
  }

  Future<void> init() async {
    _driver.onIncomingLink(_route);
    await _driver.init();
  }

  // ── Outbound: build shareable links (used by share buttons) ─────────────────
  Future<String?> shareProduct(String id) =>
      _driver.createShareLink(DeepLinkTarget.product(id));
  Future<String?> shareCart(String id) =>
      _driver.createShareLink(DeepLinkTarget.cart(id));
  Future<String?> shareReferral(String code) =>
      _driver.createShareLink(DeepLinkTarget.referral(code));

  // ── Inbound: route an incoming link (driver-agnostic) ───────────────────────
  void _route(DeepLinkTarget target) {
    switch (target.kind) {
      case DeepLinkKind.referral:
        final code = target.referralCode;
        if (code != null && code.isNotEmpty) {
          PreferenceRepository.instance.setPendingReferralCode(code);
        }
        break;
      case DeepLinkKind.product:
        if (target.productId != null) _openProduct(target.productId!);
        break;
      case DeepLinkKind.cart:
        if (target.cartId != null) _copySharedCart(target.cartId!);
        break;
      case DeepLinkKind.unknown:
        break;
    }
  }

  Future<void> _openProduct(String id) async {
    EasyLoading.show();
    try {
      final countryId = PreferenceRepository.instance.country?.id;
      final res = await getIt<DataStore>().products.retrieve(
        id,
        queryParams: {if (countryId != null) 'country_id': countryId},
      );
      EasyLoading.dismiss();
      final product = res?.product;
      if (product != null) {
        getIt<AppRouter>().push(ProductDetailsRoute(product: product));
      }
    } catch (e, st) {
      EasyLoading.dismiss();
      log('DeepLink product route failed for id=$id: $e', stackTrace: st);
    }
  }

  Future<void> _copySharedCart(String sharedCartId) async {
    EasyLoading.show();
    try {
      final res = await getIt<DataStore>().carts.retrieve(cartId: sharedCartId);
      final items = res?.cart?.items ?? const <LineItem>[];
      final myCartId = CartBloc.instance.state.whenOrNull(loaded: (c) => c.id);

      if (myCartId == null || items.isEmpty) {
        EasyLoading.dismiss();
        return;
      }

      var added = 0;
      for (final item in items) {
        final variantId = item.variantId;
        final qty = item.quantity ?? 0;
        if (variantId != null && qty > 0) {
          await getIt<DataStore>()
              .carts
              .addLineItem(cartId: myCartId, variantId: variantId, quantity: qty);
          added++;
        }
      }

      CartBloc.instance.add(const CartEvent.loadCart());
      EasyLoading.dismiss();
      if (added > 0) getIt<AppRouter>().push(const CartRoute());
    } catch (e, st) {
      EasyLoading.dismiss();
      log('DeepLink copy shared cart failed for id=$sharedCartId: $e', stackTrace: st);
    }
  }
}
