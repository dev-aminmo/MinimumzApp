import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:minimumz/common/doh_client.dart';
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
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 30),
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
    );
  }

  Future<PingResult> ping() async {
    String base = baseUrl;
    if (base.endsWith('/store')) base = base.replaceAll('/store', '');
    final url = '$base/api/store/products?limit=1';

    final pingDio = Dio(BaseOptions(
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 15),
      headers: {
        'Accept': 'application/json',
        'User-Agent': 'MiniMumz/1.0 (Mobile)',
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
      final respData = e.response?.data;
      return PingResult(
        success: false,
        statusCode: e.response?.statusCode ?? 0,
        durationMs: ms,
        url: url,
        error: e.message ?? 'Unknown error',
        body: respData is Map ? Map<String, dynamic>.from(respData) : null,
        trace: st.toString().split('\n').take(8).where((l) => l.trim().isNotEmpty).toList(),
      );
    } catch (e, st) {
      final ms = DateTime.now().difference(start).inMilliseconds;
      return PingResult(
        success: false,
        statusCode: 0,
        durationMs: ms,
        url: url,
        error: e.toString(),
        trace: st.toString().split('\n').take(8).where((l) => l.trim().isNotEmpty).toList(),
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

// Retries once after 1 s on 403 or 5xx — covers transient edge-proxy blocks.
class _RetryInterceptor extends Interceptor {
  _RetryInterceptor(this._dio);
  final Dio _dio;
  static const _maxRetries = 1;

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    final status = err.response?.statusCode;
    final extra = err.requestOptions.extra;
    final retries = (extra['_retries'] as int?) ?? 0;

    if (retries < _maxRetries && (status == 403 || (status != null && status >= 500))) {
      await Future.delayed(const Duration(seconds: 1));
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
