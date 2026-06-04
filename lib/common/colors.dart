import 'dart:ui';

class ColorConstant {
  // --kid-color-gold: primary action / active state
  static Color primary = const Color(0xffC9A88E);
  // --kid-header-bg: warm cream background
  static Color cream = const Color(0xffFFFBF5);
  // --kid-color-beige: card / surface background
  static Color beige = const Color(0xffEFE4D8);
  // --kid-color-brown-dark: muted / secondary text
  static Color manatee = const Color(0xffB08C72);
  // --kid-color-brown-darkest: dark accent text
  static Color brownDark = const Color(0xff6E4F3A);

  static Color scaffoldDark = const Color(0xff1B262C);
}

/// Parses a hex color string (e.g. "#FF0000", "f00", "FF0000FF") into a
/// [Color], or null when it isn't a usable hex value. Used to render color
/// variation swatches from API metadata.
Color? hexToColor(dynamic raw) {
  if (raw is! String) return null;
  var hex = raw.trim().replaceFirst('#', '');
  if (hex.length == 3) {
    hex = hex.split('').map((c) => '$c$c').join();
  }
  if (hex.length == 6) hex = 'FF$hex';
  if (hex.length != 8) return null;
  final value = int.tryParse(hex, radix: 16);
  return value == null ? null : Color(value);
}