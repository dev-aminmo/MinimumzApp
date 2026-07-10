import 'dart:developer';

import 'package:dio/dio.dart';
import 'package:minimumz/data/src/data/models/store/products/product.dart';

import '../models/request/index.dart';
import '../models/response/index.dart';
import 'base.dart';

class ProductsResource extends BaseResource {
  ProductsResource(super.client);

  /// @description Retrieves a list of products
  /// @param {StoreGetProductsParams} query is optional. Can contain a limit and offset for the returned list
  /// @param customHeaders
  /// @return {ResponsePromise<StoreProductsListRes>}
  Future<StoreProductsListRes?> list(
      {Map<String, dynamic>? queryParams,
      Map<String, dynamic>? customHeaders}) async {
    try {
      if (customHeaders != null) {
        client.options.headers.addAll(customHeaders);
      }
      final response = await client.get(
        '/store/products',
        queryParameters: queryParams,
      );
      if (response.statusCode == 200) {
        return StoreProductsListRes.fromJson(response.data);
      } else {
        throw response;
      }
    } catch (error,stackTrace) {
      log(error.toString(),stackTrace:stackTrace);
      rethrow;
    }
  }

  /// @description Retrieves a single Product
  /// @param {string} id is required
  /// @param customHeaders
  /// @return {ResponsePromise<StoreProductsRes>}
  Future<StoreProductsRes?> retrieve(String id,
      {Map<String, dynamic>? queryParams,
      Map<String, dynamic>? customHeaders}) async {
    try {
      if (customHeaders != null) {
        client.options.headers.addAll(customHeaders);
      }
      final response = await client.get(
        '/store/products/$id',
        queryParameters: queryParams,
      );
      if (response.statusCode == 200) {
        return StoreProductsRes.fromJson(response.data);
      } else {
        throw response;
      }
    } catch (error,stackTrace) {
      log(error.toString(),stackTrace:stackTrace);
      rethrow;
    }
  }

  /// @description Fetches recently viewed products for the logged-in user (server-side)
  Future<List<Product>> fetchRecentlyViewed({int? countryId}) async {
    try {
      final response = await client.get(
        '/store/recently-viewed',
        queryParameters: {
          if (countryId != null) 'country_id': countryId,
        },
      );
      if (response.statusCode == 200) {
        final list = response.data['products'] as List? ?? [];
        return list.map((e) => Product.fromJson(e as Map<String, dynamic>)).toList();
      }
    } catch (_) {}
    return [];
  }

  /// @description Fetches search suggestions (products + categories)
  Future<Map<String, dynamic>?> suggestions(
    String query, {
    List<String> viewedIds = const [],
    List<String> wishlistIds = const [],
  }) async {
    try {
      final response = await client.get(
        '/suggestions',
        queryParameters: {
          'query': query,
          if (viewedIds.isNotEmpty)   'viewed_ids':   viewedIds.join(','),
          if (wishlistIds.isNotEmpty) 'wishlist_ids': wishlistIds.join(','),
        },
      );
      if (response.statusCode == 200) return response.data as Map<String, dynamic>;
    } catch (_) {}
    return null;
  }

  /// @description Fetches available filter options (brands, colors, genders, price range)
  Future<Map<String, dynamic>?> fetchFilters() async {
    try {
      final response = await client.get('/store/filters');
      if (response.statusCode == 200) return response.data as Map<String, dynamic>;
    } catch (_) {}
    return null;
  }

  /// @description Searches for products
  /// @param {StorePostSearchReq} searchOptions is required
  /// @param customHeaders
  /// @return {ResponsePromise<StorePostSearchRes>}
  Future<StorePostSearchRes?> search(
      {StorePostSearchReq? req, Map<String, dynamic>? customHeaders}) async {
    try {
      if (customHeaders != null) {
        client.options.headers.addAll(customHeaders);
      }
      final response = await client
          .post('/store/products/search', data: req);
      if (response.statusCode == 200) {
        return StorePostSearchRes.fromJson(response.data);
      } else {
        throw response;
      }
    } catch (error,stackTrace) {
      log(error.toString(),stackTrace:stackTrace);
      rethrow;
    }
  }

  /// @description Visual (image) search — uploads a photo and returns visually
  /// similar products. The backend forwards the image to the vision service
  /// (CLIP + Qdrant) and returns the same {products, count} shape as `list`.
  Future<StoreProductsListRes?> imageSearch({
    required String imagePath,
    int? countryId,
    int limit = 20,
  }) async {
    try {
      final formData = FormData.fromMap({
        'image': await MultipartFile.fromFile(imagePath, filename: 'query.jpg'),
        'limit': limit,
        if (countryId != null) 'country_id': countryId,
      });
      final response = await client.post('/store/search/image', data: formData);
      if (response.statusCode == 200) {
        return StoreProductsListRes.fromJson(response.data);
      } else {
        throw response;
      }
    } catch (error, stackTrace) {
      log(error.toString(), stackTrace: stackTrace);
      rethrow;
    }
  }
}
