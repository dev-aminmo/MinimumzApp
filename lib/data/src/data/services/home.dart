import 'dart:developer';
import '../models/store/products/slider_slide.dart';
import '../models/store/products/product_collection.dart';
import '../models/store/products/brand_item.dart';
import '../models/store/products/product.dart';
import 'base.dart';

class HomeBundle {
  const HomeBundle({
    required this.slides,
    required this.collections,
    required this.brands,
    required this.bestSellers,
  });
  final List<SliderSlide> slides;
  final List<ProductCollection> collections;
  final List<BrandItem> brands;
  final List<Product> bestSellers;
}

class HomeResource extends BaseResource {
  HomeResource(super.client);

  Future<HomeBundle> fetch() async {
    try {
      final response = await client.get('/store/home');
      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;

        final sliderData = data['slider'] as Map<String, dynamic>? ?? {};
        final slides = (sliderData['slides'] as List? ?? [])
            .map((e) => SliderSlide.fromJson(e as Map<String, dynamic>))
            .toList();

        final collections = (data['collections'] as List? ?? [])
            .map((e) => ProductCollection.fromJson(e as Map<String, dynamic>))
            .toList();

        final brands = (data['brands'] as List? ?? [])
            .map((e) => BrandItem.fromJson(e as Map<String, dynamic>))
            .toList();

        final bestSellers = (data['best_sellers'] as List? ?? [])
            .map((e) => Product.fromJson(e as Map<String, dynamic>))
            .toList();

        return HomeBundle(
          slides: slides,
          collections: collections,
          brands: brands,
          bestSellers: bestSellers,
        );
      }
      throw response;
    } catch (error, stackTrace) {
      log(error.toString(), stackTrace: stackTrace);
      rethrow;
    }
  }
}
