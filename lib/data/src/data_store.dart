import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:minimumz/common/doh_client.dart';
import 'package:minimumz/common/network_log.dart';
import 'package:sentry_dio/sentry_dio.dart';
import 'data/services/index.dart';

class DataStore {
  DataStore._({
    required this.baseUrl,
    this.interceptors,
    required this.auth,
    required this.carts,
    required this.customers,
    required this.orders,
    required this.orderEdits,
    required this.products,
    required this.regions,
    required this.returnReasons,
    required this.returns,
    required this.shippingOptions,
    required this.swaps,
    required this.collections,
    required this.giftCards,
    required this.paymentMethods,
    required this.reviews,
    required this.brands,
    required this.slider,
    required this.userData,
  });

  factory DataStore.initialize({
    required String baseUrl,
    List<Interceptor>? interceptors,
  }) {
    final Dio dio = Dio();
    String baseURL = '';

    if (baseUrl.endsWith('/store')) {
      baseURL = baseUrl.replaceAll('/store', '');
    } else {
      baseURL = baseUrl;
    }

    dio.options = BaseOptions(
      baseUrl: baseURL,
      connectTimeout: const Duration(seconds: 12),
      receiveTimeout: const Duration(seconds: 12),
      headers: {
        "Accept": "application/json",
        "Content-Type": "application/json",
        "User-Agent": "MiniMumz/1.0 (Mobile)",
      },
    );

    (dio.httpClientAdapter as IOHttpClientAdapter).createHttpClient =
        makeDohHttpClient;

    interceptors?.forEach((element) {
      dio.interceptors.add(element);
    });

    dio.interceptors.add(_RetryInterceptor(dio));
    dio.addSentry();

    return DataStore._(
      baseUrl: baseUrl,
      interceptors: interceptors,
      auth: AuthResource(dio),
      carts: CartsResource(dio),
      customers: CustomersResource(dio),
      orders: OrdersResource(dio),
      orderEdits: OrderEditsResource(dio),
      products: ProductsResource(dio),
      regions: RegionsResource(dio),
      returnReasons: ReturnReasonsResource(dio),
      returns: ReturnsResource(dio),
      shippingOptions: ShippingOptionsResource(dio),
      swaps: SwapsResource(dio),
      collections: CollectionsResource(dio),
      giftCards: GiftCardsResource(dio),
      paymentMethods: PaymentMethodsResource(dio),
      reviews: ReviewsResource(dio),
      brands: BrandsResource(dio),
      slider: SliderResource(dio),
      userData: UserDataResource(dio),
    );
  }

  Future<PingResult> ping() async {
    final url = '$baseUrl/store/regions?limit=1';

    final pingDio = Dio(BaseOptions(
      connectTimeout: const Duration(seconds: 12),
      receiveTimeout: const Duration(seconds: 12),
      headers: {
        "Accept": "application/json",
        "Content-Type": "application/json",
        "User-Agent": "MiniMumz/1.0 (Mobile)",
      },
    ));
    (pingDio.httpClientAdapter as IOHttpClientAdapter).createHttpClient =
        makeDohHttpClient;

    final start = DateTime.now();
    try {
      final response = await pingDio.get(url);
      final ms = DateTime.now().difference(start).inMilliseconds;
      final body = response.data is Map
          ? Map<String, dynamic>.from(response.data as Map)
          : {'data': response.data.toString()};
      return PingResult(
        success: true,
        statusCode: response.statusCode ?? 200,
        durationMs: ms,
        url: url,
        body: body,
      );
    } on DioException catch (e, st) {
      final ms = DateTime.now().difference(start).inMilliseconds;
      final status = e.response?.statusCode ?? 0;
      final respData = e.response?.data;
      final error = _dioErrorSummary(e);
      return PingResult(
        success: false,
        statusCode: status,
        durationMs: ms,
        url: url,
        error: error,
        body: respData is Map ? Map<String, dynamic>.from(respData) : null,
        trace: st.toString().split('\n').take(6).where((l) => l.trim().isNotEmpty).toList(),
      );
    } catch (e, st) {
      final ms = DateTime.now().difference(start).inMilliseconds;
      return PingResult(
        success: false,
        statusCode: 0,
        durationMs: ms,
        url: url,
        error: e.toString(),
        trace: st.toString().split('\n').take(6).where((l) => l.trim().isNotEmpty).toList(),
      );
    }
  }

  final String baseUrl;
  final List<Interceptor>? interceptors;
  final AuthResource auth;
  final CartsResource carts;
  final CustomersResource customers;
  final OrdersResource orders;
  final OrderEditsResource orderEdits;
  final ProductsResource products;
  final RegionsResource regions;
  final ReturnReasonsResource returnReasons;
  final ReturnsResource returns;
  final ShippingOptionsResource shippingOptions;
  final SwapsResource swaps;
  final CollectionsResource collections;
  final GiftCardsResource giftCards;
  final PaymentMethodsResource paymentMethods;
  final ReviewsResource reviews;
  final BrandsResource brands;
  final SliderResource slider;
  final UserDataResource userData;
}

class PingResult {
  const PingResult({
    required this.success,
    required this.statusCode,
    required this.durationMs,
    required this.url,
    this.body,
    this.error,
    this.trace = const [],
  });

  final bool success;
  final int statusCode;
  final int durationMs;
  final String url;
  final Map<String, dynamic>? body;
  final String? error;
  final List<String> trace;
}

String _dioErrorSummary(DioException e) {
  final status = e.response?.statusCode;
  switch (e.type) {
    case DioExceptionType.connectionTimeout:
      return 'Connection timed out';
    case DioExceptionType.receiveTimeout:
      return 'Server did not respond in time';
    case DioExceptionType.connectionError:
      final msg = e.error?.toString() ?? '';
      if (msg.contains('SocketException')) {
        final match = RegExp(r'SocketException:\s*(.+?)(?:,\s*host:|$)').firstMatch(msg);
        return match != null ? match.group(1)!.trim() : 'Network unreachable';
      }
      return 'Could not reach server';
    case DioExceptionType.badResponse:
      return 'HTTP $status — ${_httpStatusText(status)}';
    case DioExceptionType.sendTimeout:
      return 'Request timed out while sending';
    case DioExceptionType.cancel:
      return 'Request cancelled';
    case DioExceptionType.unknown:
    default:
      final inner = e.error?.toString() ?? '';
      if (inner.contains('HandshakeException') || inner.contains('CERTIFICATE')) {
        return 'SSL/TLS handshake failed';
      }
      if (inner.contains('SocketException')) {
        final match = RegExp(r'SocketException:\s*(.+?)(?:,\s*host:|$)').firstMatch(inner);
        return match != null ? match.group(1)!.trim() : 'Network unreachable';
      }
      if (e.message != null && e.message!.isNotEmpty) {
        return e.message!.split('\n').first;
      }
      return inner.isNotEmpty ? inner.split('\n').first : 'Could not reach server';
  }
}

String _httpStatusText(int? code) {
  switch (code) {
    case 400: return 'Bad Request';
    case 401: return 'Unauthorized';
    case 403: return 'Forbidden';
    case 404: return 'Not Found';
    case 429: return 'Too Many Requests';
    case 500: return 'Internal Server Error';
    case 502: return 'Bad Gateway';
    case 503: return 'Service Unavailable';
    case 504: return 'Gateway Timeout';
    default:  return 'Error';
  }
}

class TrafficInterceptor extends Interceptor {
  static const _startKey = '_traffic_start';

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    options.extra[_startKey] = DateTime.now().millisecondsSinceEpoch;
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    _record(response.requestOptions,
        statusCode: response.statusCode, body: response.data);
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    _record(err.requestOptions,
        statusCode: err.response?.statusCode,
        body: err.response?.data,
        error: _dioErrorSummary(err));
    handler.next(err);
  }

  void _record(
    RequestOptions opts, {
    int? statusCode,
    dynamic body,
    String? error,
  }) {
    final startMs = opts.extra[_startKey] as int?;
    final durationMs = startMs != null
        ? DateTime.now().millisecondsSinceEpoch - startMs
        : 0;
    final reqData = opts.data;
    NetworkLog.instance.add(NetworkEntry(
      method: opts.method,
      url: opts.uri.toString(),
      requestHeaders: Map<String, dynamic>.from(opts.headers),
      requestBody:
          reqData is Map ? Map<String, dynamic>.from(reqData) : reqData?.toString(),
      statusCode: statusCode,
      responseBody: body,
      error: error,
      durationMs: durationMs,
      timestamp: DateTime.now(),
    ));
  }
}

// Retries on transient failures: 403/5xx (edge-proxy blocks) and connection
// timeouts (server blip). Uses exponential back-off: 1 s, 3 s.
class _RetryInterceptor extends Interceptor {
  _RetryInterceptor(this._dio);
  final Dio _dio;
  static const _maxRetries = 2;
  static const _delays = [Duration(seconds: 1), Duration(seconds: 3)];

  static bool _shouldRetry(DioException err) {
    final method = err.requestOptions.method.toUpperCase();
    final isReadOnly = method == 'GET' || method == 'HEAD';
    final status = err.response?.statusCode;

    // WAF/proxy blocks — safe to retry any method (no body was processed).
    if (status == 403) return true;

    // Server errors — only retry reads; writes are not idempotent.
    if (status != null && status >= 500) return isReadOnly;

    // Connection-level failures — nothing reached the server, safe for any method.
    return err.type == DioExceptionType.connectionTimeout ||
        err.type == DioExceptionType.receiveTimeout ||
        err.type == DioExceptionType.connectionError;
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    final extra = err.requestOptions.extra;
    final retries = (extra['_retries'] as int?) ?? 0;

    if (retries < _maxRetries && _shouldRetry(err)) {
      await Future.delayed(_delays[retries]);
      try {
        final opts = err.requestOptions;
        opts.extra['_retries'] = retries + 1;
        final response = await _dio.fetch(opts);
        return handler.resolve(response);
      } catch (_) {}
    }
    handler.next(err);
  }
}
