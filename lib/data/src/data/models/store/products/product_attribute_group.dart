class ProductAttributeValue {
  final String value;
  final Map<String, String> translations;

  const ProductAttributeValue({required this.value, required this.translations});

  factory ProductAttributeValue.fromJson(Map<String, dynamic> json) {
    return ProductAttributeValue(
      value: json['value'] as String? ?? '',
      translations: (json['translations'] as Map<String, dynamic>?)
              ?.map((k, v) => MapEntry(k, v as String? ?? '')) ??
          {},
    );
  }

  Map<String, dynamic> toJson() => {
        'value': value,
        'translations': translations,
      };

  String localized(String locale) =>
      translations[locale]?.isNotEmpty == true ? translations[locale]! : value;
}

class ProductAttributeItem {
  final String attributeId;
  final String attributeName;
  final Map<String, String> attributeTranslations;
  final List<ProductAttributeValue> values;

  const ProductAttributeItem({
    required this.attributeId,
    required this.attributeName,
    required this.attributeTranslations,
    required this.values,
  });

  factory ProductAttributeItem.fromJson(Map<String, dynamic> json) {
    return ProductAttributeItem(
      attributeId: json['attribute_id']?.toString() ?? '',
      attributeName: json['attribute_name'] as String? ?? '',
      attributeTranslations:
          (json['attribute_translations'] as Map<String, dynamic>?)
                  ?.map((k, v) => MapEntry(k, v as String? ?? '')) ??
              {},
      values: (json['values'] as List<dynamic>?)
              ?.map((e) => ProductAttributeValue.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() => {
        'attribute_id': attributeId,
        'attribute_name': attributeName,
        'attribute_translations': attributeTranslations,
        'values': values.map((v) => v.toJson()).toList(),
      };

  String localizedName(String locale) =>
      attributeTranslations[locale]?.isNotEmpty == true
          ? attributeTranslations[locale]!
          : attributeName;
}

class ProductAttributeGroup {
  final String setId;
  final String setName;
  final Map<String, String> setTranslations;
  final List<ProductAttributeItem> attributes;

  const ProductAttributeGroup({
    required this.setId,
    required this.setName,
    required this.setTranslations,
    required this.attributes,
  });

  factory ProductAttributeGroup.fromJson(Map<String, dynamic> json) {
    return ProductAttributeGroup(
      setId: json['set_id']?.toString() ?? '',
      setName: json['set_name'] as String? ?? '',
      setTranslations:
          (json['set_translations'] as Map<String, dynamic>?)
                  ?.map((k, v) => MapEntry(k, v as String? ?? '')) ??
              {},
      attributes: (json['attributes'] as List<dynamic>?)
              ?.map((e) => ProductAttributeItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() => {
        'set_id': setId,
        'set_name': setName,
        'set_translations': setTranslations,
        'attributes': attributes.map((a) => a.toJson()).toList(),
      };

  String localizedSetName(String locale) =>
      setTranslations[locale]?.isNotEmpty == true
          ? setTranslations[locale]!
          : setName;
}
