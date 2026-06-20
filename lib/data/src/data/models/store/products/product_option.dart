import 'product_option_value.dart';
import 'product.dart';

class ProductOption {
  final String? id;
  final String? title;
  final Map<String, String>? translations;
  final List<ProductOptionValue>? values;
  final String? productId;
  final Product? product;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? deletedAt;
  final Map<String, dynamic>? metadata;

  ProductOption({
    this.id,
    required this.title,
    this.translations,
    this.values,
    required this.productId,
    this.product,
    this.createdAt,
    this.updatedAt,
    this.deletedAt,
    this.metadata,
  });

  String localizedTitle(String locale) {
    final t = translations?[locale];
    if (t != null && t.isNotEmpty) return t;
    return title ?? '';
  }

  factory ProductOption.fromJson(Map<String, dynamic> json) {
    List<ProductOptionValue>? values;
    if (json['values'] != null) {
      values = <ProductOptionValue>[];
      json['values'].forEach((e) => values!.add(ProductOptionValue.fromJson(e)));
    }

    Map<String, String>? translations;
    if (json['translations'] is Map) {
      translations = Map<String, String>.from(
        (json['translations'] as Map).map((k, v) => MapEntry(k.toString(), v?.toString() ?? '')),
      );
    }

    return ProductOption(
      id: json['id'],
      title: json['title'],
      translations: translations,
      productId: json['product_id'],
      product: json['product'] != null ? Product.fromJson(json['product']) : null,
      values: values,
      createdAt: DateTime.tryParse(json['created_at'] ?? ''),
      updatedAt: DateTime.tryParse(json['updated_at'] ?? ''),
      deletedAt: DateTime.tryParse(json['deleted_at'] ?? ''),
      metadata: json['metadata'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'translations': translations,
      'values': values?.map((e) => e.toJson()).toList(),
      'product_id': productId,
      'product': product?.toJson(),
      'created_at': createdAt.toString(),
      'updated_at': updatedAt.toString(),
      'deleted_at': deletedAt.toString(),
      'metadata': metadata,
    };
  }
}
