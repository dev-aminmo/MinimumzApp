import 'product_option.dart';
import 'product_variant.dart';

class ProductOptionValue {
  final String? id;
  final String? value;
  final Map<String, String>? translations;
  final String? optionId;
  final ProductOption? option;
  final String? variantId;
  final ProductVariant? variant;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? deletedAt;
  final Map<String, dynamic>? metadata;

  ProductOptionValue({
    this.id,
    required this.value,
    this.translations,
    required this.optionId,
    this.option,
    required this.variantId,
    this.variant,
    this.createdAt,
    this.updatedAt,
    this.deletedAt,
    this.metadata,
  });

  String localizedValue(String locale) {
    final t = translations?[locale];
    if (t != null && t.isNotEmpty) return t;
    return value ?? '';
  }

  factory ProductOptionValue.fromJson(Map<String, dynamic> json) {
    Map<String, String>? translations;
    if (json['translations'] is Map) {
      translations = Map<String, String>.from(
        (json['translations'] as Map).map((k, v) => MapEntry(k.toString(), v?.toString() ?? '')),
      );
    }

    return ProductOptionValue(
      id: json['id'],
      value: json['value'],
      translations: translations,
      optionId: json['option_id'],
      variantId: json['variant_id'],
      option: json['option'] != null ? ProductOption.fromJson(json) : null,
      variant: json['variant'] != null ? ProductVariant.fromJson(json) : null,
      createdAt: DateTime.tryParse(json['created_at'] ?? '')?.toLocal(),
      updatedAt: DateTime.tryParse(json['updated_at'] ?? '')?.toLocal(),
      deletedAt: DateTime.tryParse(json['deleted_at'] ?? '')?.toLocal(),
      metadata: json['metadata'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'value': value,
      'translations': translations,
      'option_id': optionId,
      'option': option?.toJson(),
      'variant_id': variantId,
      'variant': variant?.toJson(),
      'created_at': createdAt.toString(),
      'updated_at': updatedAt.toString(),
      'deleted_at': deletedAt.toString(),
      'metadata': metadata,
    };
  }
}
