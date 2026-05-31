class ProductFilter {
  final String? sortBy;       // null | price_asc | price_desc | rating | created_at | best_sellers
  final double? minPrice;
  final double? maxPrice;
  final List<String> genders; // e.g. ['male','female']
  final List<String> brandIds;
  final List<String> colors;  // hex values
  final int? minAge;
  final int? maxAge;

  const ProductFilter({
    this.sortBy,
    this.minPrice,
    this.maxPrice,
    this.genders = const [],
    this.brandIds = const [],
    this.colors = const [],
    this.minAge,
    this.maxAge,
  });

  static const empty = ProductFilter();

  bool get isEmpty =>
      sortBy == null &&
      minPrice == null &&
      maxPrice == null &&
      genders.isEmpty &&
      brandIds.isEmpty &&
      colors.isEmpty &&
      minAge == null &&
      maxAge == null;

  int get activeCount {
    int n = 0;
    if (minPrice != null || maxPrice != null) n++;
    if (genders.isNotEmpty) n++;
    if (brandIds.isNotEmpty) n++;
    if (colors.isNotEmpty) n++;
    if (minAge != null || maxAge != null) n++;
    return n;
  }

  ProductFilter copyWith({
    Object? sortBy = _sentinel,
    Object? minPrice = _sentinel,
    Object? maxPrice = _sentinel,
    List<String>? genders,
    List<String>? brandIds,
    List<String>? colors,
    Object? minAge = _sentinel,
    Object? maxAge = _sentinel,
  }) {
    return ProductFilter(
      sortBy:   sortBy   == _sentinel ? this.sortBy   : sortBy   as String?,
      minPrice: minPrice == _sentinel ? this.minPrice : minPrice as double?,
      maxPrice: maxPrice == _sentinel ? this.maxPrice : maxPrice as double?,
      genders:  genders  ?? this.genders,
      brandIds: brandIds ?? this.brandIds,
      colors:   colors   ?? this.colors,
      minAge:   minAge   == _sentinel ? this.minAge   : minAge   as int?,
      maxAge:   maxAge   == _sentinel ? this.maxAge   : maxAge   as int?,
    );
  }

  Map<String, dynamic> toQueryParams() {
    final params = <String, dynamic>{};
    if (sortBy != null)           params['sort']      = sortBy;
    if (minPrice != null)         params['min_price'] = minPrice;
    if (maxPrice != null)         params['max_price'] = maxPrice;
    if (genders.isNotEmpty)       params['gender']    = genders.join(',');
    if (brandIds.isNotEmpty)      params['type_id']   = brandIds.join(',');
    if (colors.isNotEmpty)        params['colors']    = colors.join(',');
    if (minAge != null)           params['age_min']   = minAge;
    if (maxAge != null)           params['age_max']   = maxAge;
    return params;
  }
}

// Sentinel for nullable copyWith params
const _sentinel = Object();
