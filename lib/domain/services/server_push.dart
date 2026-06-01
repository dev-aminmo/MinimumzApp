import 'dart:developer';
import 'package:minimumz/data/data.dart';
import 'package:minimumz/di/di.dart';
import 'package:minimumz/domain/repository/preference_repository.dart';

/// Fire-and-forget: push wishlist IDs to the server when the user is logged in.
Future<void> pushWishlistToServer(List<Product> products) async {
  if (PreferenceRepository.instance.isGuest) return;
  try {
    final ids = products.map((p) => p.id ?? '').where((id) => id.isNotEmpty).toList();
    await getIt<DataStore>().userData.update(wishlistIds: ids);
  } catch (e) {
    log('pushWishlistToServer: $e');
  }
}

/// Fire-and-forget: push search history to the server when the user is logged in.
Future<void> pushSearchHistoryToServer(List<String> history) async {
  if (PreferenceRepository.instance.isGuest) return;
  try {
    await getIt<DataStore>().userData.update(searchHistory: history);
  } catch (e) {
    log('pushSearchHistoryToServer: $e');
  }
}
