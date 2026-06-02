import 'dart:math';
import 'package:minimumz/data/src/data/models/store/others/money_amount.dart';
import 'package:minimumz/data/src/data/models/store/products/product.dart';

List<Product> filterPricedProducts(List<Product> products) {
  return products.where((p) {
    return (p.variants ?? [])
        .expand((v) => v.prices ?? <MoneyAmount>[])
        .any((m) => m.amount != null && m.amount! > 0);
  }).toList();
}

extension MoneyAmountListPricing on List<MoneyAmount> {
  // All entries with amount > 0 for the requested currency.
  // Falls back to all valid entries if no currency match exists.
  List<MoneyAmount> _validFor(String currencyCode) {
    final code = currencyCode.toUpperCase();
    final all = where((p) => p.amount != null && p.amount! > 0).toList();
    if (all.isEmpty) return [];
    final match = all.where((p) => p.currencyCode?.toUpperCase() == code).toList();
    return match.isNotEmpty ? match : all;
  }

  int? minPrice(String currencyCode) {
    final valid = _validFor(currencyCode);
    if (valid.isEmpty) return null;
    return valid.map((p) => p.amount!).reduce(min);
  }

  String effectiveCurrency(String currencyCode) {
    final code = currencyCode.toUpperCase();
    final all = where((p) => p.amount != null && p.amount! > 0).toList();
    if (all.isEmpty) return code;
    final hasMatch = all.any((p) => p.currencyCode?.toUpperCase() == code);
    return hasMatch ? code : (all.first.currencyCode?.toUpperCase() ?? code);
  }

  int? maxCompareAt(String currencyCode, int price) {
    final code = currencyCode.toUpperCase();
    final matching = where((p) =>
        p.currencyCode?.toUpperCase() == code &&
        p.compareAtAmount != null &&
        p.compareAtAmount! > price);
    if (matching.isEmpty) return null;
    return matching.map((p) => p.compareAtAmount!).reduce(max);
  }
}
