import 'package:dio/dio.dart';

class GeoIpService {
  static final _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 5),
    receiveTimeout: const Duration(seconds: 5),
    responseType: ResponseType.plain,
  ));

  static const _allowedCountries = ['SA', 'BH'];

  /// Detects the user's country from their IP address.
  /// Returns 'SA' if the detected country is not in the allowed list,
  /// or if the detection fails for any reason.
  static Future<String> detectCountryCode() async {
    try {
      final response = await _dio.get('https://ipapi.co/country_code/');
      if (response.statusCode == 200) {
        final code = response.data.toString().trim().toUpperCase();
        if (code.length == 2 && _allowedCountries.contains(code)) {
          return code;
        }
      }
    } catch (_) {}
    return 'SA';
  }
}
