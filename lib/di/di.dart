import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:minimumz/data/src/data_store.dart';
import 'package:minimumz/presentation/routes/app_router.dart';

import 'di.config.dart';
import 'module.dart';

final GetIt getIt = GetIt.instance;

@InjectableInit()
Future<void> configureInjection() async {
  final prefs = await SharedPreferences.getInstance();
  getIt.registerSingleton<SharedPreferences>(prefs);
  getIt.registerSingleton<AppRouter>(AppRouter());
  getIt.registerSingleton<DataStore>(RegisterCoreDependencies.createDataStore());
  getIt.init();
}
