import 'package:flutter/foundation.dart';

class CountryChangeNotifier extends ChangeNotifier {
  static final CountryChangeNotifier instance = CountryChangeNotifier._();
  CountryChangeNotifier._();

  void notify() => notifyListeners();
}
