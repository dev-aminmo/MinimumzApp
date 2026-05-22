import 'dart:developer';
import 'base.dart';

class ReviewItem {
  final int id;
  final String reviewerName;
  final double rating;
  final String comment;
  final String? createdAt;

  const ReviewItem({
    required this.id,
    required this.reviewerName,
    required this.rating,
    required this.comment,
    this.createdAt,
  });

  factory ReviewItem.fromJson(Map<String, dynamic> json) => ReviewItem(
        id: json['id'] as int,
        reviewerName: (json['reviewer_name'] as String?) ?? 'Anonymous',
        rating: (json['rating'] as num).toDouble(),
        comment: (json['comment'] as String?) ?? '',
        createdAt: json['created_at'] as String?,
      );
}

class ReviewsListResult {
  final List<ReviewItem> reviews;
  final int count;
  final double avgRating;

  const ReviewsListResult({
    required this.reviews,
    required this.count,
    required this.avgRating,
  });
}

class ReviewsResource extends BaseResource {
  ReviewsResource(super.client);

  Future<ReviewsListResult> list({
    required String productId,
    int limit = 10,
    int offset = 0,
  }) async {
    try {
      final response = await client.get(
        '/store/products/$productId/reviews',
        queryParameters: {'limit': limit, 'offset': offset},
      );
      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        final list = (data['reviews'] as List)
            .map((e) => ReviewItem.fromJson(e as Map<String, dynamic>))
            .toList();
        return ReviewsListResult(
          reviews: list,
          count: data['count'] as int,
          avgRating: (data['avg_rating'] as num).toDouble(),
        );
      }
      throw response;
    } catch (e, stack) {
      log(e.toString(), stackTrace: stack);
      rethrow;
    }
  }

  Future<void> create({
    required String productId,
    required String reviewerName,
    required String comment,
    required int rating,
  }) async {
    try {
      final response = await client.post(
        '/store/products/$productId/reviews',
        data: {
          'reviewer_name': reviewerName,
          'comment': comment,
          'rating': rating,
        },
      );
      if (response.statusCode != 200) throw response;
    } catch (e, stack) {
      log(e.toString(), stackTrace: stack);
      rethrow;
    }
  }
}
