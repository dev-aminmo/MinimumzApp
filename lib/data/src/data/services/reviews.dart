import 'dart:developer';
import 'package:dio/dio.dart';
import 'base.dart';

class ReviewItem {
  final int id;
  final String reviewerName;
  final double rating;
  final String comment;
  final String? createdAt;
  final List<String> images;

  const ReviewItem({
    required this.id,
    required this.reviewerName,
    required this.rating,
    required this.comment,
    this.createdAt,
    this.images = const [],
  });

  factory ReviewItem.fromJson(Map<String, dynamic> json) => ReviewItem(
        id: json['id'] as int,
        reviewerName: (json['reviewer_name'] as String?) ?? 'Anonymous',
        rating: (json['rating'] as num).toDouble(),
        comment: (json['comment'] as String?) ?? '',
        createdAt: json['created_at'] as String?,
        images: (json['images'] as List?)?.map((e) => e.toString()).toList() ?? [],
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
    List<String> imagePaths = const [],
  }) async {
    try {
      final formData = FormData();
      formData.fields.add(MapEntry('reviewer_name', reviewerName));
      formData.fields.add(MapEntry('comment', comment));
      formData.fields.add(MapEntry('rating', rating.toString()));
      for (final path in imagePaths) {
        formData.files.add(MapEntry(
          'images[]',
          await MultipartFile.fromFile(path),
        ));
      }
      final response = await client.post(
        '/store/products/$productId/reviews',
        data: formData,
      );
      if (response.statusCode != 200) throw response;
    } catch (e, stack) {
      log(e.toString(), stackTrace: stack);
      rethrow;
    }
  }

  Future<void> recordView({
    required String productId,
    required String sessionId,
  }) async {
    try {
      await client.post(
        '/store/products/$productId/view',
        data: {'session_id': sessionId},
      );
    } catch (_) {}
  }
}
