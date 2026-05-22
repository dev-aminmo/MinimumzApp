import '../store/others/index.dart';

class StoreShippingOptionsListRes {
  List<ShippingOption>? shippingOptions;

  StoreShippingOptionsListRes.fromJson(json) {
    List? rawList;
    if (json is List) {
      rawList = json;
    } else if (json is Map) {
      rawList = json['shipping_options'] as List?;
    }
    if (rawList != null) {
      shippingOptions = rawList
          .whereType<Map>()
          .map((v) => ShippingOption.fromJson(v as Map<String, dynamic>))
          .toList();
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['shipping_options'] =
        shippingOptions?.map((e) => e.toJson()).toList();
    return data;
  }
}
