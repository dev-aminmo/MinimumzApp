import 'dart:developer';
import '../models/store/products/slider_slide.dart';
import 'base.dart';

class SliderResource extends BaseResource {
  SliderResource(super.client);

  Future<List<SliderSlide>> fetch() async {
    try {
      final response = await client.get('/store/slider');
      if (response.statusCode == 200) {
        final data = response.data['slides'] as List<dynamic>? ?? [];
        return data
            .map((e) => SliderSlide.fromJson(e as Map<String, dynamic>))
            .toList();
      } else {
        throw response;
      }
    } catch (error, stackTrace) {
      log(error.toString(), stackTrace: stackTrace);
      rethrow;
    }
  }
}
