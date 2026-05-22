import 'dart:developer';
import '../models/store/products/brand_item.dart';
import 'base.dart';

class BrandsResource extends BaseResource {
  BrandsResource(super.client);

  Future<List<BrandItem>> list({int limit = 50, int offset = 0}) async {
    try {
      final response = await client.get('/store/brands', queryParameters: {
        'limit': limit,
        'offset': offset,
      });
      if (response.statusCode == 200) {
        final data = response.data['brands'] as List<dynamic>? ?? [];
        return data.map((e) => BrandItem.fromJson(e as Map<String, dynamic>)).toList();
      } else {
        throw response;
      }
    } catch (error, stackTrace) {
      log(error.toString(), stackTrace: stackTrace);
      rethrow;
    }
  }
}
