import 'dart:developer';
import 'package:minimumz/cubits/wishlist/wishlist_cubit.dart';
import 'package:minimumz/data/data.dart';
import 'package:minimumz/di/di.dart';
import 'package:minimumz/domain/repository/preference_repository.dart';
import 'package:minimumz/domain/services/server_push.dart';

/// Merges local wishlist / search-history with the server copy and pushes merged data back.
/// Call once immediately after login or signup succeeds.
Future<void> syncUserDataOnLogin(WishlistCubit wishlistCubit) async {
  if (PreferenceRepository.instance.isGuest) return;
  try {
    final remote = await getIt<DataStore>().userData.get();
    if (remote == null) return;

    // ── Wishlist ───────────────────────────────────────────────────────────
    final localProducts = PreferenceRepository.instance.wishlistProducts;
    final localIds = localProducts.map((p) => p.id ?? '').where((id) => id.isNotEmpty).toSet();
    final remoteIds = remote.wishlistIds.where((id) => id.isNotEmpty).toSet();
    final mergedIds = {...localIds, ...remoteIds}.toList();

    // ── Search history ─────────────────────────────────────────────────────
    final localHistory = PreferenceRepository.instance.searchHistory;
    final mergedHistory = [
      ...localHistory,
      ...remote.searchHistory.where((q) => !localHistory.contains(q)),
    ].take(10).toList();

    // Push merged data back to server in one call.
    await getIt<DataStore>().userData.update(
      wishlistIds: mergedIds,
      searchHistory: mergedHistory,
    );

    // Persist merged search history locally.
    await _writeSearchHistory(mergedHistory);

    // If server had extra IDs not in local wishlist, fetch their product objects.
    final extraIds = remoteIds.difference(localIds);
    if (extraIds.isNotEmpty) {
      try {
        final fetched = await getIt<DataStore>().products.list(
          queryParams: {'ids[]': extraIds.toList(), 'limit': extraIds.length},
        );
        final extra = fetched?.products ?? [];
        final combined = [...localProducts, ...extra];
        await PreferenceRepository.instance.setWishlistProducts(combined);
        wishlistCubit.reload();
      } catch (e) {
        log('syncUserDataOnLogin: fetch remote products failed: $e');
      }
    }
  } catch (e) {
    log('syncUserDataOnLogin error: $e');
  }
}

/// Writes [items] directly as the full search history (bypasses addSearchHistory
/// to avoid redundant server pushes during restore).
Future<void> _writeSearchHistory(List<String> items) async {
  await PreferenceRepository.instance.clearSearchHistory();
  // addSearchHistory inserts at front, so iterate reversed to preserve order.
  for (final item in items.reversed) {
    await PreferenceRepository.instance.addSearchHistoryLocal(item);
  }
}
