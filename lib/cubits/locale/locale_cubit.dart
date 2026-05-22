import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:minimumz/di/di.dart';
import 'package:shared_preferences/shared_preferences.dart';

@singleton
class LocaleCubit extends Cubit<Locale> {
  LocaleCubit(this._prefs) : super(const Locale('en')) {
    _load();
  }

  static LocaleCubit get instance => getIt<LocaleCubit>();

  final SharedPreferences _prefs;
  static const _key = 'locale';

  void _load() {
    final saved = _prefs.getString(_key);
    if (saved != null) emit(Locale(saved));
  }

  Future<void> setLocale(Locale locale) async {
    await _prefs.setString(_key, locale.languageCode);
    emit(locale);
  }
}
