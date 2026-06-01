import 'dart:math';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:minimumz/common/enums.dart';
import 'package:timeago/timeago.dart' as timeago;

export 'l10n_extension.dart';

extension BuildContextEntension<T> on BuildContext {
  // text styles

  TextStyle? get headlineLarge => Theme.of(this).textTheme.headlineLarge;
  TextStyle? get headlineMedium => Theme.of(this).textTheme.headlineMedium;
  TextStyle? get headlineSmall => Theme.of(this).textTheme.headlineSmall;

  TextStyle? get bodyLarge => Theme.of(this).textTheme.bodyLarge;
  TextStyle? get bodyMedium => Theme.of(this).textTheme.bodyMedium;
  TextStyle? get bodySmall => Theme.of(this).textTheme.bodySmall;
  TextStyle? get bodyExtraSmall => bodySmallW500?.copyWith(fontSize: 11);

  TextStyle? get bodyLargeW500 => Theme.of(this).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w500);
  TextStyle? get bodyMediumW500 => Theme.of(this).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500);
  TextStyle? get bodySmallW500 => Theme.of(this).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w500);
  TextStyle? get bodyExtraSmallW500 => bodySmallW500?.copyWith(fontSize: 11, fontWeight: FontWeight.w500);

  TextStyle? get bodyLargeW600 => Theme.of(this).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600);
  TextStyle? get bodyMediumW600 => Theme.of(this).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600);

  // theme
  ThemeData get theme => Theme.of(this);

  // media query
  EdgeInsets get viewPadding => MediaQuery.of(this).viewPadding;
  double get bottomViewPadding => MediaQuery.of(this).viewPadding.bottom;
  EdgeInsets get viewInsets => MediaQuery.of(this).viewInsets;
  EdgeInsets get padding => MediaQuery.of(this).padding;


  // Directionality
  bool get isRTL => Directionality.of(this) == TextDirection.rtl;

}

extension TextStyleColor on TextStyle {
  TextStyle dark() {
    return copyWith(color: Colors.white);
  }
}
extension Unique<E, Id> on List<E> {
  List<E> unique([Id Function(E element)? id, bool inplace = true]) {
    final ids = <dynamic>{};
    var list = inplace ? this : List<E>.from(this);
    list.retainWhere((x) => ids.add(id != null ? id(x) : x as Id));
    return list;
  }
}

// Returns the number of decimal places (subunit exponent) for a currency code.
// Must match the backend CartController::currencyDecimals() and
// ProductResource::currencyDecimals() helpers.
int currencyDecimals(String code) {
  switch (code.toUpperCase()) {
    case 'JPY':
    case 'KRW':
    case 'VND':
      return 0;
    default:
      return 2;
  }
}

/// Returns the display symbol for a currency, optionally localised.
/// Falls back to the ISO code if no override is defined.
String currencySymbol(String code, {String? locale}) {
  final upper = code.toUpperCase();
  final lang  = (locale ?? '').split('_').first.toLowerCase();
  if (lang == 'ar') {
    switch (upper) {
      case 'SAR': return '﷼';
      case 'BHD': return 'د.ب';
    }
  }
  return upper;
}

extension FormatPrice on num? {
  String formatAsPrice(String? currencyCode,
      {bool includeSymbol = true,
      bool space = true,
      bool symbolAtEnd = false,
      String? locale}) {
    if (this == null || currencyCode == null) return this?.toString() ?? '';
    final code     = currencyCode.toUpperCase();
    final decimals = currencyDecimals(code);
    final value    = this! / pow(10, decimals);
    final isInteger = value == value.toInt();
    final formatted =
        NumberFormat.currency(name: code, symbol: '', decimalDigits: isInteger ? 0 : decimals)
            .format(value)
            .trim();
    if (!includeSymbol) return formatted;
    final symbol = currencySymbol(code, locale: locale);
    return (!symbolAtEnd ? symbol : '') +
        (space && !symbolAtEnd ? ' ' : '') +
        formatted +
        (space && symbolAtEnd ? ' ' : '') +
        (symbolAtEnd ? symbol : '');
  }

  num formatAsPriceNum(String? currencyCode) {
    if (this == null || currencyCode == null) return this ?? 0.0;
    return this! / pow(10, currencyDecimals(currencyCode.toUpperCase()));
  }
}


extension FormatDate on DateTime? {
  String formatDate() {
    if (this == null) {
      return '';
    }
    return DateFormat(DateFormatOptions.eighth.toPattern()).format(this!);
  }

  String formatTime() {
    if (this == null) {
      return '';
    }
    return DateFormat(DateFormatOptions.eighth.toPattern()).format(this!);
  }

  String timeAgo() {
    if (this == null) {
      return '';
    }
    return timeago.format(this!);
  }
}
