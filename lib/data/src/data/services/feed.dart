import 'dart:developer';

import 'package:minimumz/data/src/data/models/store/products/product.dart';

import 'base.dart';

/// A page of the personalized "For You" feed.
///
/// The server materializes a ranked snapshot per session and paginates by
/// slicing it, so the client just carries `session` + `offset` forward.
class FeedPage {
  FeedPage({
    required this.products,
    required this.session,
    required this.nextOffset,
    required this.hasMore,
    required this.count,
  });

  final List<Product> products;
  final String? session;
  final int nextOffset;
  final bool hasMore;
  final int count;

  factory FeedPage.fromJson(Map<String, dynamic> json) {
    final list = <Product>[];
    if (json['products'] != null) {
      for (final v in json['products']) {
        list.add(Product.fromJson(v));
      }
    }
    return FeedPage(
      products: list,
      session: json['session'] as String?,
      nextOffset: (json['next_offset'] ?? 0) as int,
      hasMore: json['has_more'] == true,
      count: (json['count'] ?? list.length) as int,
    );
  }
}

class FeedResource extends BaseResource {
  FeedResource(super.client);

  /// GET /store/me/feed — personalized paginated feed.
  /// Pass the same [session] across pages; omit it on the first call / refresh
  /// so the server mints a fresh session (new rotation + seen-set).
  Future<FeedPage?> fetch({
    String? session,
    int offset = 0,
    int limit = 20,
    int? countryId,
  }) async {
    try {
      final response = await client.get('/store/me/feed', queryParameters: {
        'offset': offset,
        'limit': limit,
        if (session != null) 'session': session,
        if (countryId != null) 'country_id': countryId,
      });
      if (response.statusCode == 200) {
        return FeedPage.fromJson(response.data);
      }
      throw response;
    } catch (error, stackTrace) {
      log(error.toString(), stackTrace: stackTrace);
      rethrow;
    }
  }
}
