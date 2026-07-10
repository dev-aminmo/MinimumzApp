import 'package:dio/dio.dart';
import 'package:minimumz/cubits/locale/locale_cubit.dart';
import 'package:minimumz/data/src/data_store.dart';
import 'package:minimumz/domain/repository/preference_repository.dart';

abstract class RegisterCoreDependencies {
  static DataStore createDataStore() => DataStore.initialize(
      // TEMP local testing — restore the Hostinger URL before uploading to server.
      //baseUrl: 'http://192.168.10.51:8000/api',
      baseUrl: 'http://157.245.240.32:8000/api',
      //baseUrl: 'https://darkorchid-mouse-412686.hostingersite.com/api',
      //baseUrl: 'https://google.com/api',
      interceptors: [_authInterceptor, _localeInterceptor, TrafficInterceptor()],
  );

  static final Interceptor _localeInterceptor = InterceptorsWrapper(
    onRequest: (options, handler) {
      try {
        final locale = LocaleCubit.instance.state.languageCode;
        options.headers['Accept-Language'] = locale;
      } catch (_) {}
      handler.next(options);
    },
  );

  static final Interceptor _authInterceptor = InterceptorsWrapper(
    onRequest: (options, handler) {
      try {
        final String? jwt = PreferenceRepository.instance.cookie;
        if (jwt != null && jwt.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $jwt';
        }
      } catch (_) {}
      handler.next(options);
    },
    onError: (DioException e, handler) {
      if (e.response?.statusCode == 401) {
        // Fire-and-forget: don't await so handler.next is called immediately.
        PreferenceRepository.instance.deleteCookie().catchError((_) {});
      }
      handler.next(e);
    },
  );
}
