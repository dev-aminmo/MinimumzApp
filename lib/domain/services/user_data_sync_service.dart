import 'dart:developer';
import 'package:minimumz/cubits/wishlist/wishlist_cubit.dart';
import 'package:minimumz/data/data.dart';
import 'package:minimumz/di/di.dart';
import 'package:minimumz/domain/repository/preference_repository.dart';
import 'package:minimumz/domain/services/server_push.dart';
import 'package:minimumz/presentation/screens/cart/bloc/cart/cart_bloc.dart';

Future<void> syncUserDataOnLogin(WishlistCubit wishlistCubit) async {
  if (PreferenceRepository.instance.isGuest) return;
  try {
    final remote = await getIt<DataStore>().userData.get();
    if (remote == null) return;

    final localProducts = PreferenceRepository.instance.wishlistProducts;
    final localIds = localProducts.map((p) => p.id ?? '').where((id) => id.isNotEmpty).toSet();
    final remoteIds = remote.wishlistIds.where((id) => id.isNotEmpty).toSet();
    final mergedIds = {...localIds, ...remoteIds}.toList();

    final localHistory = PreferenceRepository.instance.searchHistory;
    final mergedHistory = [
      ...localHistory,
      ...remote.searchHistory.where((q) => !localHistory.contains(q)),
    ].take(10).toList();

    await getIt<DataStore>().userData.update(
      wishlistIds: mergedIds,
      searchHistory: mergedHistory,
    );

    await _writeSearchHistory(mergedHistory);

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

    await filterWishlistForCountry(wishlistCubit);
  } catch (e) {
    log('syncUserDataOnLogin error: $e');
  }
}

Future<void> filterWishlistForCountry(WishlistCubit wishlistCubit) async {
  final countryId = PreferenceRepository.instance.country?.id;
  if (countryId == null) {
    await PreferenceRepository.instance.clearWishlistAvailableIds();
    return;
  }
  final ids = wishlistCubit.state
      .map((p) => p.id)
      .whereType<String>()
      .toList();
  if (ids.isEmpty) {
    await PreferenceRepository.instance.setWishlistAvailableIds({});
    return;
  }
  try {
    final result = await getIt<DataStore>().products.list(queryParams: {
      'id[]': ids,
      'limit': ids.length,
      'country_id': countryId,
    });
    final refreshed = result?.products ?? [];
    final availableIds = refreshed.map((p) => p.id).whereType<String>().toSet();
    await PreferenceRepository.instance.setWishlistAvailableIds(availableIds);
    await wishlistCubit.refreshPrices(refreshed);
  } catch (_) {}
}

Future<void> clearUserDataOnLogout(WishlistCubit wishlistCubit, CartBloc cartBloc) async {
  await PreferenceRepository.instance.clearUserSessionData();
  wishlistCubit.reload();
  cartBloc.add(const CartEvent.loadCart());
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
