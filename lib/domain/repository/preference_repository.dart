import 'dart:convert';
import 'dart:developer';

import 'package:injectable/injectable.dart';
import 'package:minimumz/di/di.dart';
import 'package:minimumz/data/data.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:minimumz/domain/services/server_push.dart';

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
  static const String _fcmTokenKey = 'registered_fcm_token';
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

  // ── Cached order details (per id) ─────────────────────────────────────────
  static const String _cachedOrdersKey = 'cached_order_details';
  static const int _maxCachedOrders = 20;

  /// Returns the cached order-detail JSON for [id], or null if not cached.
  Map<String, dynamic>? cachedOrderDetail(String id) {
    try {
      final raw = _prefs.getString(_cachedOrdersKey);
      if (raw == null) return null;
      final map = jsonDecode(raw) as Map<String, dynamic>;
      final entry = map[id];
      return entry is Map<String, dynamic> ? entry : null;
    } catch (_) {
      return null;
    }
  }

  Future<void> setCachedOrderDetail(String id, Map<String, dynamic> json) async {
    try {
      final raw = _prefs.getString(_cachedOrdersKey);
      final map = raw != null
          ? Map<String, dynamic>.from(jsonDecode(raw) as Map<String, dynamic>)
          : <String, dynamic>{};
      map.remove(id); // re-insert at the end to keep recency order
      map[id] = json;
      while (map.length > _maxCachedOrders) {
        map.remove(map.keys.first);
      }
      await _prefs.setString(_cachedOrdersKey, jsonEncode(map));
    } catch (e) {
      log(e.toString());
    }
  }

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

  // ── Brands cache ─────────────────────────────────────────────────────────────
  static const String _cachedBrandsKey = 'cached_brands';

  List<BrandItem>? get cachedBrands {
    final raw = _prefs.getString(_cachedBrandsKey);
    if (raw == null) return null;
    try {
      final list = jsonDecode(raw) as List;
      return list.map((e) => BrandItem.fromJson(e as Map<String, dynamic>)).toList();
    } catch (e) {
      log(e.toString());
      return null;
    }
  }

  Future<void> setCachedBrands(List<BrandItem> brands) async {
    try {
      await _prefs.setString(
        _cachedBrandsKey,
        jsonEncode(brands.map((b) => b.toJson()).toList()),
      );
    } catch (e) {
      log(e.toString());
    }
  }

  // ── New Arrivals cache ────────────────────────────────────────────────────────
  static const String _cachedNewArrivalsKey = 'cached_new_arrivals';

  List<Product>? get cachedNewArrivals {
    final raw = _prefs.getString(_cachedNewArrivalsKey);
    if (raw == null) return null;
    try {
      final list = jsonDecode(raw) as List;
      return list.map((e) => Product.fromJson(e as Map<String, dynamic>)).toList();
    } catch (e) {
      log(e.toString());
      return null;
    }
  }

  Future<void> setCachedNewArrivals(List<Product> products) async {
    try {
      await _prefs.setString(
        _cachedNewArrivalsKey,
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
      _prefs.remove(_cachedBrandsKey),
      _prefs.remove(_cachedNewArrivalsKey),
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

  /// The FCM token last successfully registered with the backend. Used to skip
  /// redundant updates when the device token hasn't changed.
  String? get registeredFcmToken => _prefs.getString(_fcmTokenKey);

  Future<void> setRegisteredFcmToken(String? token) async {
    if (token == null || token.isEmpty) {
      await _prefs.remove(_fcmTokenKey);
    } else {
      await _prefs.setString(_fcmTokenKey, token);
    }
  }

  // ── Recently viewed ──────────────────────────────────────────────────────────
  static const String _recentlyViewedKey = 'recently_viewed';
  static const int _maxRecentlyViewed = 20;

  List<Map<String, dynamic>> get recentlyViewed {
    try {
      final list = _prefs.getStringList(_recentlyViewedKey) ?? [];
      return list.map((s) => jsonDecode(s) as Map<String, dynamic>).toList();
    } catch (_) {
      return [];
    }
  }

  List<String> get recentlyViewedIds =>
      recentlyViewed.map((m) => m['id'] as String? ?? '').where((id) => id.isNotEmpty).toList();

  Future<void> addRecentlyViewed({
    required String id,
    required String title,
    String? thumbnail,
  }) async {
    final current = recentlyViewed.where((m) => m['id'] != id).toList();
    current.insert(0, {
      'id': id,
      'title': title,
      if (thumbnail != null) 'thumbnail': thumbnail,
    });
    await _prefs.setStringList(
      _recentlyViewedKey,
      current.take(_maxRecentlyViewed).map((m) => jsonEncode(m)).toList(),
    );
  }

  // ── Wishlist available IDs (country-filtered) ────────────────────────────────
  static const String _wishlistAvailableIdsKey = 'wishlist_available_ids';

  Set<String>? get wishlistAvailableIds {
    final raw = _prefs.getStringList(_wishlistAvailableIdsKey);
    if (raw == null) return null;
    return raw.toSet();
  }

  Future<void> setWishlistAvailableIds(Set<String> ids) async =>
      await _prefs.setStringList(_wishlistAvailableIdsKey, ids.toList());

  Future<void> clearWishlistAvailableIds() async =>
      await _prefs.remove(_wishlistAvailableIdsKey);

  // ── Addresses cache ───────────────────────────────────────────────────────────
  static const String _cachedAddressesKey = 'cached_addresses';

  List<Address>? get cachedAddresses {
    final raw = _prefs.getString(_cachedAddressesKey);
    if (raw == null) return null;
    try {
      final list = jsonDecode(raw) as List;
      return list.map((e) => Address.fromJson(e as Map<String, dynamic>)).toList();
    } catch (e) {
      log(e.toString());
      return null;
    }
  }

  Future<void> setCachedAddresses(List<Address> addresses) async {
    try {
      await _prefs.setString(
        _cachedAddressesKey,
        jsonEncode(addresses.map((a) => a.toJson()).toList()),
      );
    } catch (e) {
      log(e.toString());
    }
  }

  Future<void> clearCachedAddresses() async =>
      _prefs.remove(_cachedAddressesKey);

  // ── Search history ────────────────────────────────────────────────────────────
  static const String _searchHistoryKey = 'search_history';
  static const int _maxHistoryItems = 10;

  List<String> get searchHistory {
    try {
      return _prefs.getStringList(_searchHistoryKey) ?? [];
    } catch (e) {
      return [];
    }
  }

  Future<void> addSearchHistory(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return;
    final history = searchHistory.where((q) => q != trimmed).toList();
    history.insert(0, trimmed);
    final updated = history.take(_maxHistoryItems).toList();
    await _prefs.setStringList(_searchHistoryKey, updated);
    pushSearchHistoryToServer(updated);
  }

  /// Like [addSearchHistory] but skips the server push (used during sync restore).
  Future<void> addSearchHistoryLocal(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return;
    final history = searchHistory.where((q) => q != trimmed).toList();
    history.insert(0, trimmed);
    await _prefs.setStringList(
      _searchHistoryKey,
      history.take(_maxHistoryItems).toList(),
    );
  }

  Future<void> removeSearchHistory(String query) async {
    final history = searchHistory.where((q) => q != query).toList();
    await _prefs.setStringList(_searchHistoryKey, history);
  }

  Future<void> clearSearchHistory() async =>
      await _prefs.remove(_searchHistoryKey);

  Future<void> clearUserSessionData() async {
    setGuest(value: true);
    // Restore currency to the selected region's currency, discarding the
    // account-specific override set on login.
    final regionCurrency = _region?.currencyCode;
    if (regionCurrency != null && regionCurrency.isNotEmpty) {
      await setCurrencyCode(regionCurrency);
    } else {
      await clearCurrencyCode();
    }
    await Future.wait([
      clearCartId(),
      clearCachedCart(),
      clearSearchHistory(),
      clearWishlistAvailableIds(),
      _prefs.remove(_wishlistKey),
      _prefs.remove(_recentlyViewedKey),
    ]);
  }

  Future<void> setWishlistProducts(List<Product> products) async {
    await _prefs.setString(
      _wishlistKey,
      jsonEncode(products.map((p) => p.toJson()).toList()),
    );
  }
}
