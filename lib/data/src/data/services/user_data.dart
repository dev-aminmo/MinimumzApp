import 'dart:developer';
import 'base.dart';

class UserAppData {
  const UserAppData({required this.wishlistIds, required this.searchHistory});

  factory UserAppData.fromJson(Map<String, dynamic> json) => UserAppData(
        wishlistIds: (json['wishlist_ids'] as List?)?.map((e) => e as String).toList() ?? [],
        searchHistory: (json['search_history'] as List?)?.map((e) => e as String).toList() ?? [],
      );

  final List<String> wishlistIds;
  final List<String> searchHistory;
}

class UserDataResource extends BaseResource {
  UserDataResource(super.client);

  Future<UserAppData?> get() async {
    try {
      final response = await client.get('/store/me/data');
      if (response.statusCode == 200) {
        return UserAppData.fromJson(response.data as Map<String, dynamic>);
      }
    } catch (error, stackTrace) {
      log(error.toString(), stackTrace: stackTrace);
    }
    return null;
  }

  Future<UserAppData?> update({
    List<String>? wishlistIds,
    List<String>? searchHistory,
  }) async {
    try {
      final body = <String, dynamic>{};
      if (wishlistIds != null) body['wishlist_ids'] = wishlistIds;
      if (searchHistory != null) body['search_history'] = searchHistory;

      final response = await client.post('/store/me/data', data: body);
      if (response.statusCode == 200) {
        return UserAppData.fromJson(response.data as Map<String, dynamic>);
      }
    } catch (error, stackTrace) {
      log(error.toString(), stackTrace: stackTrace);
    }
    return null;
  }
}
