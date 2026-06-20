import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:minimumz/data/src/data/models/store/products/product.dart';
import 'package:minimumz/domain/repository/preference_repository.dart';
import 'package:minimumz/domain/services/server_push.dart';

class WishlistCubit extends Cubit<List<Product>> {
  WishlistCubit() : super(PreferenceRepository.instance.wishlistProducts);

  Timer? _syncDebounce;

  bool isWishlisted(String? productId) =>
      productId != null && state.any((p) => p.id == productId);

  Future<void> toggle(Product product) async {
    final updated = List<Product>.from(state);
    final idx = updated.indexWhere((p) => p.id == product.id);
    if (idx >= 0) {
      updated.removeAt(idx);
    } else {
      updated.add(product);
    }
    await PreferenceRepository.instance.setWishlistProducts(updated);
    emit(List.unmodifiable(updated));
    // Debounce server sync — rapid toggles coalesce into one request.
    _syncDebounce?.cancel();
    _syncDebounce = Timer(const Duration(milliseconds: 800), () {
      _syncDebounce = null;
      pushWishlistToServer(updated);
    });
  }

  /// Reloads state from local storage (e.g. after server sync updates local prefs).
  void reload() {
    emit(List.unmodifiable(PreferenceRepository.instance.wishlistProducts));
  }

  /// Replaces stored products with freshly fetched ones (updated prices).
  /// Products missing from [refreshed] keep their existing data.
  Future<void> refreshPrices(List<Product> refreshed) async {
    if (refreshed.isEmpty) return;
    final byId = {for (final p in refreshed) p.id: p};
    final updated = state.map((p) => byId[p.id] ?? p).toList();
    await PreferenceRepository.instance.setWishlistProducts(updated);
    emit(List.unmodifiable(updated));
  }
}
