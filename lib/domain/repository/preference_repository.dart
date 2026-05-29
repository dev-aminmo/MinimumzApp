import 'dart:convert';
import 'dart:developer';

import 'package:injectable/injectable.dart';
import 'package:minimumz/di/di.dart';
import 'package:minimumz/data/data.dart';
import 'package:shared_preferences/shared_preferences.dart';

@singleton
class PreferenceRepository {
  PreferenceRepository(this._prefs);
  final SharedPreferences _prefs;
  static PreferenceRepository get instance => getIt<PreferenceRepository>();

  // Generated once per app launch; used to deduplicate product view counts.
  static final String sessionId =
      DateTime.now().millisecondsSinceEpoch.toRadixString(36) +
      DateTime.now().microsecond.toRadixString(36);

  @postConstruct
  void init() {
    try {
      if (_prefs.getString(_countryKey) != null) {
        _country = Country.fromJson(jsonDecode(_prefs.getString(_countryKey)!));
      }

      if (_prefs.getString(_regionKey) != null) {
        _region = Region.fromJson(jsonDecode(_prefs.getString(_regionKey)!));
      }
    } catch (e) {
      log(e.toString());
    }
  }

  static const String _guestKey = 'guest';
  static const String _cartKey = 'cart';
  static const String _regionKey = 'region';
  static const String _countryKey = 'country';
  static const String _cookie = 'cookie';
  static const String _currencyCodeKey = 'currency_code';
  static const String _wishlistKey = 'wishlist';
  static const String _notificationsKey = 'notifications_enabled';
  static const String _regionsKey = 'cached_regions';

  bool get isGuest => _prefs.getBool(_guestKey) ?? false;
  String? get cartId => _prefs.getString(_cartKey);
  String? get cookie => _prefs.getString(_cookie);
  Future<void> setCookie(String cookie) async => await _prefs.setString(_cookie, cookie);
  Future<void> deleteCookie() async => await _prefs.remove(_cookie);
  Country? _country;
  Region? _region;
  Country? get country => _country;
  Region? get region => _region;

  /// Returns the currency code for the current user's country.
  /// Prefers the stored customer currency, falls back to region, then USD.
  static String get currencyCode {
    final stored = instance._prefs.getString(_currencyCodeKey);
    if (stored != null && stored.isNotEmpty) return stored;
    return instance._region?.currencyCode?.toUpperCase() ?? 'SAR';
  }

  Future<void> setCurrencyCode(String code) async =>
      await _prefs.setString(_currencyCodeKey, code.toUpperCase());

  Future<void> clearCurrencyCode() async => await _prefs.remove(_currencyCodeKey);

  void setGuest({bool? value}) => _prefs.setBool(_guestKey, value ?? true);
  Future<bool> setCartId(String cartId) async =>
      await _prefs.setString(_cartKey, cartId);

  Future<void> clearCartId() async => await _prefs.remove(_cartKey);

  Future<bool> setCountry(Country country) async {
    try {
      final jsonCountry = jsonEncode(country.toJson());
      _country = country;
      return await _prefs.setString(_countryKey, jsonCountry);
    } catch (e) {
      log(e.toString());
      return false;
    }
  }

  List<Region>? get cachedRegions {
    final raw = _prefs.getString(_regionsKey);
    if (raw == null) return null;
    try {
      final list = jsonDecode(raw) as List;
      return list.map((e) => Region.fromJson(e as Map<String, dynamic>)).toList();
    } catch (e) {
      log(e.toString());
      return null;
    }
  }

  Future<void> setCachedRegions(List<Region> regions) async {
    await _prefs.setString(
      _regionsKey,
      jsonEncode(regions.map((r) => r.toJson()).toList()),
    );
  }

  Future<bool> setRegion(Region region) async {
    try {
      final jsonRegion = jsonEncode(region.toJson());
      _region = region;
      return await _prefs.setString(_regionKey, jsonRegion);
    } catch (e) {
      log(e.toString());
      return false;
    }
  }

  List<Product> get wishlistProducts {
    final raw = _prefs.getString(_wishlistKey);
    if (raw == null) return [];
    try {
      final list = jsonDecode(raw) as List;
      return list.map((e) => Product.fromJson(e as Map<String, dynamic>)).toList();
    } catch (e) {
      log(e.toString());
      return [];
    }
  }

  // ── Cart cache ──────────────────────────────────────────────────────────────
  static const String _cachedCartKey = 'cached_cart';

  Cart? get cachedCart {
    final raw = _prefs.getString(_cachedCartKey);
    if (raw == null) return null;
    try {
      return Cart.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (e) {
      log(e.toString());
      return null;
    }
  }

  Future<void> setCachedCart(Cart cart) async {
    try {
      await _prefs.setString(_cachedCartKey, jsonEncode(cart.toJson()));
    } catch (e) {
      log(e.toString());
    }
  }

  Future<void> clearCachedCart() async => _prefs.remove(_cachedCartKey);

  // ── Best sellers cache ────────────────────────────────────────────────────────
  static const String _cachedBestSellersKey = 'cached_best_sellers';

  List<Product>? get cachedBestSellers {
    final raw = _prefs.getString(_cachedBestSellersKey);
    if (raw == null) return null;
    try {
      final list = jsonDecode(raw) as List;
      return list.map((e) => Product.fromJson(e as Map<String, dynamic>)).toList();
    } catch (e) {
      log(e.toString());
      return null;
    }
  }

  Future<void> setCachedBestSellers(List<Product> products) async {
    try {
      await _prefs.setString(
        _cachedBestSellersKey,
        jsonEncode(products.map((p) => p.toJson()).toList()),
      );
    } catch (e) {
      log(e.toString());
    }
  }

  // ── Locale-sensitive cache clearing ──────────────────────────────────────────
  Future<void> clearLocaleSensitiveCaches() async {
    await Future.wait([
      _prefs.remove(_cachedCollectionsKey),
      _prefs.remove(_cachedBestSellersKey),
      _prefs.remove(_cachedSliderKey),
    ]);
  }

  // ── Collections cache ─────────────────────────────────────────────────────────
  static const String _cachedCollectionsKey = 'cached_collections';

  List<ProductCollection>? get cachedCollections {
    final raw = _prefs.getString(_cachedCollectionsKey);
    if (raw == null) return null;
    try {
      final list = jsonDecode(raw) as List;
      return list.map((e) => ProductCollection.fromJson(e as Map<String, dynamic>)).toList();
    } catch (e) {
      log(e.toString());
      return null;
    }
  }

  Future<void> setCachedCollections(List<ProductCollection> collections) async {
    try {
      await _prefs.setString(
        _cachedCollectionsKey,
        jsonEncode(collections.map((c) => c.toJson()).toList()),
      );
    } catch (e) {
      log(e.toString());
    }
  }

  // ── Slider cache ─────────────────────────────────────────────────────────────
  static const String _cachedSliderKey = 'cached_slider';

  List<SliderSlide>? get cachedSlider {
    final raw = _prefs.getString(_cachedSliderKey);
    if (raw == null) return null;
    try {
      final list = jsonDecode(raw) as List;
      return list.map((e) => SliderSlide.fromJson(e as Map<String, dynamic>)).toList();
    } catch (e) {
      log(e.toString());
      return null;
    }
  }

  Future<void> setCachedSlider(List<SliderSlide> slides) async {
    try {
      await _prefs.setString(
        _cachedSliderKey,
        jsonEncode(slides.map((s) => s.toJson()).toList()),
      );
    } catch (e) {
      log(e.toString());
    }
  }

  bool get notificationsEnabled => _prefs.getBool(_notificationsKey) ?? true;

  Future<void> setNotificationsEnabled(bool value) async =>
      await _prefs.setBool(_notificationsKey, value);

  Future<void> setWishlistProducts(List<Product> products) async {
    await _prefs.setString(
      _wishlistKey,
      jsonEncode(products.map((p) => p.toJson()).toList()),
    );
  }
}
